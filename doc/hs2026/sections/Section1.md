<!------------------------------------------------------------------------------

# Simply-Typed Lambda Calculus

```haskell
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE EmptyCase #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE PatternGuards #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeData #-}
```

```haskell
module Section1 where
```

```haskell
import Data.Kind (Type)
import Prelude hiding ((!!))
```

------------------------------------------------------------------------------->

```haskell
type data Nat = Z | S Nat
```

```haskell
data Ix (n :: Nat) where
  FZ  ::          Ix (S n)
  FS  :: Ix n ->  Ix (S n)
```

```haskell
data Ty
  =  Bot
  |  Ty :-> Ty
```

```haskell
data TmInf  n
  =  Ann  (TmChk n) Ty
  |  Var  (Ix n)
  |  App  (TmInf n) (TmChk n)
```

```haskell
data TmChk  n
  =  Inf  (TmInf n)
  |  Lam  (TmChk (S n))
```

<!------------------------------------------------------------------------------

```haskell
deriving instance Eq Ty
deriving instance Show Ty
```

------------------------------------------------------------------------------->

```haskell
data Env (n :: Nat) (a :: Type) where
  Nil   ::                  Env  Z      a
  (:>)  :: Env n a -> a ->  Env  (S n)  a
```

```haskell
(!!) :: Env n a -> Ix n -> a
γ :> a  !! FZ    = a
γ :> a  !! FS i  = γ !! i
```

```haskell
check :: Env n Ty -> TmChk n -> Ty -> Bool
check γ  (Inf  e)     τ           = infer γ e == Just τ
check γ  (Lam  e)     (τ :-> τ')  = check (γ :> τ) e τ'
```

```haskell
infer :: Env n Ty -> TmInf n -> Maybe Ty
infer γ = \case
  Ann e τ   | check γ e τ                                 -> Just τ
  Var i                                                   -> Just (γ !! i)
  App e e'  | Just (τ :-> τ') <- infer γ e, check γ e' τ  -> Just τ'
  _                                                       -> Nothing
```

```haskell
idTm :: TmInf n
idTm = Ann (Lam (Inf (Var FZ))) (Bot :-> Bot)
```

- [ ] Add an example that requires thinnings and composition
