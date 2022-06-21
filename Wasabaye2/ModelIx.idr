module Wasabaye2.ModelIx

import Data.Subset
import Data.List
import Wasabaye2.Env


||| A model indexed by an environment of random variables
data ModelIx : (env : List (String, Type)) -> (x : Type) -> Type where
  Pure      : a -> ModelIx [] a
  Bind      : {env1, env2 : _} -> ModelIx env1 a -> (a -> ModelIx env2 b) -> ModelIx (env1 ++ env2) b
  Normal    : (mu : Double) -> (std : Double) -> (y : String) -> ModelIx [(y, Double)] Double
  Uniform   : (min : Double) -> (max : Double) -> (y : String) -> ModelIx [(y, Double)] Double
  Bernoulli : (p : Double) -> (y : String) -> ModelIx [(y, Bool)] Bool
-- | "If" returns a model indexed by both branches' sample spaces.
  If        : (b : Bool) -> (m1 : ModelIx env1 a) -> (m2 : ModelIx env2 a) -> ModelIx (env1 ++ env2) a

-- | "iF" returns a model indexed by one of the branches' sample space.
iF : Bool -> (ModelIx omega1 a) -> (ModelIx omega2 a) -> (b ** ModelIx (if b then omega1 else omega2) a)
iF True m1 m2  = (True ** m1)
iF False m1 m2 = (False ** m2)

pure : a -> ModelIx [] a
pure = Pure

(>>=) : {env1, env2 : _} -> ModelIx env1 a -> (a -> ModelIx env2 b) -> ModelIx (env1 ++ env2) b
(>>=) = Bind {env1} {env2}

normal    = Normal
uniform   = Uniform
bernoulli = Bernoulli

-- Example 1
exampleModelIx : ModelIx [("x", Double)] Double
exampleModelIx = do
  x <- normal 0 2 "x"
  pure x

exampleModelIxImpl : ModelIx [("x", Double)] Double
exampleModelIxImpl = do
  ((>>=) {env1 = [("x", Double)]}) (normal 0 2 "x")  (\x => pure x)

-- Example 2 
exampleModelIx2 : ModelIx [("p", Bool), ("y", Double)] Double
exampleModelIx2 = do
  b <- bernoulli 0.5 "p"
  y <- If b (pure 6) (Normal 0 1 "y")
  pure y

-- Example 3
exampleModelIx3 : ModelIx [("b", Bool)] (b ** ModelIx (if b then [] else [("y", Double)]) Double)
exampleModelIx3 = do
  b <- Bernoulli 0.5 "b"
  let m = iF b (pure 6) (Normal 0 1 "y")
  case m of (True ** m1)  => pure (True ** m1)
            (False ** m2) => pure (False ** m2)

||| Environment

subsetConcat : Subset env (env ++ env')
subsetConcat = ?subsetConcat_rhs

%hint
subsetConcatInv1 : Subset (env1 ++ env2) env  -> Subset env1 env
subsetConcatInv2 : Subset (env1 ++ env2) env  -> Subset env2 env

subsetCong   : Subset env env' -> Subset env' env'' -> Subset env env''

partial
interpretModelIx : (prf : Subset env env_sup) => Env env_sup -> ModelIx env a -> a
interpretModelIx ENil (Pure x)   = x
interpretModelIx env (Bind x k) = 
  let v = interpretModelIx {prf = subsetConcatInv1 prf} env x 
  in  interpretModelIx {prf = subsetConcatInv2 prf} env (k v)
-- interpretModelIx env (Normal mu std y) = head $ get "y" env
-- interpretModelIx env (Uniform min max y) = ?r_15
-- interpretModelIx env (Bernoulli p y) = True
-- interpretModelIx env (If b m1 m2) = 
--   if b then interpretModelIx env m1 else interpretModelIx env m2

