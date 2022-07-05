module ProbFX.Examples.HMM

import Data.List
import Data.List1
import ProbFX.Model as PFX
import ProbFX.Sampler
import ProbFX.Inference.SIM
import ProbFX.Inference.MBAYES
import Control.Monad.Bayes.Interface
import Control.Monad.Bayes.Sampler
import Control.Monad.Bayes.Traced.Static
import Control.Monad.Bayes.Weighted

||| A generic transition model
TransModel : List (String, Type) -> List (Type -> Type) -> Type -> Type -> Type
TransModel env es params lat   = params -> lat -> Model env es lat

||| A generic observation model
ObsModel   : List (String, Type) -> List (Type -> Type) -> Type -> Type -> Type -> Type
ObsModel env es params lat obsv = params -> lat -> Model env es obsv

||| A generic chain of HMM nodes
hmmChain : 
     (transPrior : Model env es ps1)
  -> (obsPrior   : Model env es ps2)
  -> (transModel : TransModel env es ps1 lat) 
  -> (obsModel   : ObsModel env es ps2 lat obsv)
  -> (hmm_length : Nat) 
  -> (input_lat  : lat) 
  -> Model env es (List1 lat)
hmmChain transPrior obsPrior transModel obsModel n x_0 = do
  ps1    <- transPrior
  ps2    <- obsPrior
  let hmmNode : List1 lat -> Model env es (List1 lat)
      hmmNode (x ::: xs) = do
            x' <- transModel ps1 x
            y' <- obsModel ps2 x'
            pure (x' ::: (x :: xs)) 
  foldl (>=>) pure (List.replicate n hmmNode) (x_0 ::: [])

||| Example HMM
boolToNat : Bool -> Nat
boolToNat True  = 1
boolToNat False = 0

transPrior : Observable env "trans_p" Double => Model env es Double
transPrior = PFX.uniform 0 1 "trans_p" 

obsPrior : Observable env "obs_p" Double => Model env es Double
obsPrior = Model.uniform 0 1 "obs_p" 

transModel :  Double -> Nat -> Model env es Nat
transModel transition_p x_prev = do
  dX <- boolToNat <$> PFX.bernoulli' transition_p
  pure (dX + x_prev)
  
obsModel : (Observable env "y" Nat)
  => Double -> Nat -> Model env es Nat
obsModel observation_p x = do
  PFX.binomial x observation_p "y"

hmm : (Observables env ["trans_p", "obs_p"] Double, Observable env "y" Nat) 
  => (len : Nat) -> (input : Nat) -> Model env es (List1 Nat) 
hmm = hmmChain transPrior obsPrior transModel obsModel

||| Example HMM environment and data
HMMEnv : List (String, Type)
HMMEnv =  [("trans_p", Double), ("obs_p", Double), ("y", Nat)]

envExampleSim : Env HMMEnv
envExampleSim = ("trans_p" ::= [0.9]) <:> ("obs_p" ::= [0.4]) <:> ("y" ::=  []) <:> ENil

envExampleInf: List Nat -> Env HMMEnv
envExampleInf ys = ("trans_p" ::= []) <:> ("obs_p" ::= []) <:> ("y" ::= ys) <:> ENil

example_ys : List Nat  -- | using trans_p = 0.9, obs_p = 0.4
example_ys = [0, 0, 0, 2, 1, 2, 1, 2, 3, 2, 1, 3, 4, 5, 5, 4, 3, 7, 7, 8, 5, 6, 5, 9, 8, 7, 7, 11, 10, 10, 9, 13, 9, 13, 14, 9, 10, 10, 17, 17, 16, 19, 19, 13, 13, 18, 20, 16, 21, 20] 
  
x_0 : Nat -- | Starting latent state
x_0 = 0 

||| Executing example HMM 
export
simHmm : (hmm_length : Nat) -> IO (List (Nat, Nat))
simHmm hmm_length = do
  (xs, env_out) <- runSampler (simulate envExampleSim (hmm hmm_length x_0) )
  let ys = get "y" env_out
  pure (zip (List1.forget xs) ys)

export
simHmmMB : (hmm_length : Nat) -> IO (List (Nat, Nat))
simHmmMB hmm_length = do 
  let hmmMB = toMBayes envExampleSim (hmm hmm_length x_0) 
  (xs, env_out) <- sampleIO $ prior hmmMB
  let ys = get "y" env_out
  pure (zip (List1.forget xs) ys)

export
mhHmmMB : (n_mhsteps : Nat) -> (hmm_length : Nat) -> IO (List Double, List Double)
mhHmmMB n_mhsteps hmm_length = do 
  let hmmMB = toMBayes (envExampleInf example_ys) (hmm hmm_length x_0) 

  mh_output <- sampleIO $ prior $ mh n_mhsteps hmmMB
  let mh_env_outs : List (Env HMMEnv) = map snd (toList mh_output)
      trans_ps : List Double          = gets "trans_p" mh_env_outs
      obs_ps   : List Double          = gets "obs_p" mh_env_outs
  pure (trans_ps, obs_ps)
