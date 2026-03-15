<!------------------------------------------------------------------------------

# Simply-Typed Lambda Calculus

```haskell
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE TypeOperators #-}
```

```haskell
module Section2 where
```

```haskell
import Section1 (Nat (..), Ty (..))
```

------------------------------------------------------------------------------->


```haskell
data (m :: Nat) >= (n :: Nat) where
  KeepAll  ::                 m  >=    m
  KeepOne  ::  m >= n  ->  S  m  >= S  n
  DropOne  ::  m >= n  ->  S  m  >=    n
```

```haskell
data Th f m = Th (m >= n) (f n)
```

```haskell
data TmInf (n :: Nat) where
  Ann  :: TmChk n     -> Ty          ->  TmInf n
  Var  ::                                TmInf Z
  App  :: Th TmInf n  -> Th TmChk n  ->  TmInf n
```

```haskell
data TmChk  (n :: Nat) where
  Inf  :: TmInf n      ->  TmChk n
  Lam  :: TmChk (S n)  ->  TmChk n
```
