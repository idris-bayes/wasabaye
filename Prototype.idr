{- This is perhaps too much of an abstraction, but I was trying hard to think about what high-level goals I wanted to achieve without considering too much about the tools I had access to. These ideas might be trash, and I don't know if what I'm trying to achieve is meaningful. I think research into seeing how probabilistic programming or data science can creatively benefit from an expressive type-system is really exciting, and I'm very amenable to what you think is a good idea to do, and happy to embark on a completely different journey in this area; this could mean focusing my efforts on monad-bayes with Jacob.


Goal: A front-end language that allows the programmer to define probabilistic models using statistical modeling notation, allowing one to express relations (~) between random variables and distributions, and other properties of RVs using types. 
```
          linRegr : Double -> Model Double
          linRegr x = do
            mu  ~ Uniform 0 1
            std ~ HalfNormal 1
            y   ~ Normal (mu * x) std
```
Some possible properties:

  1) The set of random variables (RVs) of a model can be identified:
        i) Perhaps through an explicit context of RVs under which the model is typed:
```
              { (mu : Double), (std : Double), (y : Double) } ⊦ linRegr : Double -> Model Double
```
        ii) Or by some operation "random_vars" that given a model definition, returns its RVs as a type:
```
              random_vars : (m : Model) -> Env []
              random_vars linRegr = { (mu : Double), (std : Double), (y : Double) } 
```
  2)  To execute a model, this requires each RV to be given a list of observed values, determining if they are to be "sampled" or "observed". 
      ```
        execute : (m : Model a) -> (env : random_vars m) -> a
```
      To avoid an unintended case of a RV defaulting to Sample when running out of observed values, perhaps we could apply some type-level Nat constraints on the number of observed values required.

      We could encode more expressive ways (than lists) of determining when observed values are specifically used.

  3) The RVs of a model can only be used once statically, and can only be associated with a primitive distribution.

        Example 1:

          linRegr : Double -> Model Double     
          linRegr x = do                      
            mu  ~ Uniform 0 1                     
            mu  ~ Uniform 0 2      <- Not allowed
            std ~ HalfNormal 1
            y   ~ Normal (mu * x) std

        Example 2:
        
          prior : Model (Double, Double)      
          prior = do
            mu  ~ Uniform 0 1                     
            std ~ HalfNormal 1

          linRegr : Model (Double, Double) -> Double -> Model Double
          linRegr prior x = do
            (mu, std) <- prior            <- this is fine (not a primitive distribution)
            mu ~ Uniform 0 1              <- not allowed, as 'mu' is already distributed in 'prior'
            y  ~ Normal (mu * x) std

      When two models are combined but have RV name clashes, perhaps it could be interesting to try and implement a renaming mechanism.
-}

data Env : (env : List (String, Type))  -> Type where
  ENil  : Env []
  ECons : (var : String) -> (val : ty) -> Env env -> Env ((var, ty) :: env)

data Prog : (env : List (String, Type)) -> (x : Type) -> Type where
  Pure  : a -> Prog [] a
  Bind  : {xs, ys : _} -> Prog xs a -> (a -> Prog ys b) -> Prog (xs ++ ys) b

decompEnv : (xs : _) -> Env (xs ++ ys) -> (Env xs, Env ys)
decompEnv Nil es = (ENil, es)
decompEnv ((str, ty) :: vs) (ECons str val envs) 
  = let (xs_rest, ys) = decompEnv vs envs
    in  (ECons str val xs_rest, ys)

evalMIx : Env env -> Prog env a -> a
evalMIx ENil (Pure x) = x
evalMIx env (Bind mx k {xs} {ys}) = 
  let (env_xs, env_ys) = decompEnv xs env
      x = evalMIx env_xs mx 
  in  evalMIx env_ys (k x)