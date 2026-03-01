# Abstract

This is our abstract.

# Fancy-Feast for Type Theorists

What? Yes.

```haskell
data Ix (n :: Nat) where
  FZ  ::          Ix (S n)
  FS  :: Ix n ->  Ix (S n)
```

```haskell
newtype Ix (n :: Nat) = UnsafeIx {value :: Int}
```

```haskell
makeFZ :: Ix (S n)
makeFZ = UnsafeIx { value = 0 }
```

```haskell
makeFS :: Ix n -> Ix (S n)
makeFS ix = UnsafeIx { value = ix.value + 1 }
```

```haskell
elimIx :: a -> (Ix (Pred n) -> a) -> Ix n -> a
elimIx ifFZ ifFS ix
  | ix.value == 0  = ifFZ
  | otherwise      = ifFS UnsafeIx { value = ix.value - 1 }
```

```haskell
data IxF (ix :: Nat -> Type) (n :: Nat) where
  FZF  ::             IxF ix (S m)
  FSF  :: !(ix m) ->  IxF ix (S m)
```

```haskell
projectIx :: Ix n -> IxF Ix n
projectIx = elimIx (unsafeCoerce FZF) (unsafeCoerce FSF)
```

```haskell
embedIx :: IxF Ix n -> Ix n
embedIx   FZF      = makeFZ
embedIx ( FSF ix)  = makeFS ix
```

```haskell
pattern  FZ :: () => (Pos n) => Ix n
pattern  FZ <- (projectIx -> FZF)
  where  FZ = embedIx FZF
```

```haskell
pattern  FS :: () => (Pos n) => Ix (Pred n) -> Ix n
pattern  FS ix  <- (projectIx -> FSF ix)
  where  FS ix  = embedIx (FSF ix)
```
