{-# OPTIONS --without-K #-}
module category.free.list {i j}{X : Set i}(W : X → X → Set j) where

open import sum
open import level using (_⊔_)
open import equality.core hiding (singleton)
open import equality.calculus
open import equality.reasoning
open import sets.nat using (refl-≤)
open import hott.hlevel

data List : X → X → Set (i ⊔ j) where
  nil : ∀ {x} → List x x
  _∷_ : ∀ {x y z}
      → W x y
      → List y z
      → List x z
infixr 5 _∷_

Term : Set (i ⊔ j)
Term = Σ (X × X) (uncurry W)

private
  module HLevel (hX : h 3 X)(hW : h 2 Term) where
    open import decidable
    open import sum
    open import sets.empty
    open import sets.unit
    open import function.extensionality
    open import function.isomorphism
    open import w renaming (W to W-type)
    open import hott.hlevel.properties

    I : Set i
    I = X × X 

    A : I → Set _
    A (x , y) = (x ≡ y) ⊎ Σ Term λ { ((x' , y') , w) → (x' ≡ x) }

    A-hlevel : (i : I) → h 2 (A i)
    A-hlevel (x , y) = ⊎-hlevel (refl-≤ 2) (hX x y)
      (Σ-hlevel hW (λ { ((x' , _) , _) → hX x' x }))

    B : (i : I) → A i → Set _
    B (x , .x) (inj₁ refl) = ⊥
    B (.x , z) (inj₂ (((x , y) , w) , refl)) = ⊤

    r : (i : I)(a : A i) → B i a → I
    r (x , .x) (inj₁ refl) ()
    r (.x , z) (inj₂ (((x , y) , w) , refl)) _ = y , z

    List' : X → X → Set _
    List' x y = W-type I A B r (x , y)

    list-iso : (x y : X) → List' x y ≅ List x y
    list-iso _ _ = iso f g iso₁ iso₂
      where
        f : {x y : X} → List' x y → List x y
        f {x}{.x} (sup (inj₁ refl) _) = nil
        f {.x}{z} (sup (inj₂ (((x , y) , w) , refl)) u) = w ∷ f (u tt)

        g : {x y : X} → List x y → List' x y
        g {x}{.x} nil = sup (inj₁ refl) (λ ())
        g {.x}{.z} (_∷_ {x}{y}{z} w ws) =
          sup (inj₂ (((x , y) , w) , refl)) (λ _ → g ws)

        iso₁ : {x y : X}(ws : List' x y) → g (f ws) ≡ ws
        iso₁ {x}{.x} (sup (inj₁ refl) _) = cong (sup (inj₁ refl)) (ext' λ ())
        iso₁ {.x}{z} (sup (inj₂ (((x , y) , w) , refl)) u) =
          cong (sup (inj₂ (((x , y) , w) , refl))) (ext λ { tt → iso₁ (u tt) })

        iso₂ : {x y : X}(ws : List x y) → f (g ws) ≡ ws
        iso₂ {x}{.x} nil = refl
        iso₂ (w ∷ ws) = cong (_∷_ w) (iso₂ ws)

    list-hlevel : (x y : X) → h 2 (List x y)
    list-hlevel x y = iso-hlevel (list-iso x y) (w-hlevel (λ { (x , y) → A-hlevel (x , y) }) (x , y))
open HLevel using (list-hlevel)

_++_ : ∀ {x y z} → List x y → List y z → List x z
nil ++ ws = ws
(u ∷ us) ++ ws = u ∷ (us ++ ws)
infixl 5 _++_

assoc++ : ∀ {x y z w}(ws : List x y)(us : List y z)(vs : List z w)
        → ws ++ (us ++ vs)
        ≡ ws ++ us ++ vs
assoc++ nil us vs = refl
assoc++ (w ∷ ws) us vs = cong (λ α → w ∷ α) (assoc++ ws us vs)

nil-right-inverse : ∀ {x y} (ws : List x y)
                  → ws ++ nil ≡ ws
nil-right-inverse nil = refl
nil-right-inverse (w ∷ ws) =
  cong (λ ws → w ∷ ws)
       (nil-right-inverse ws)
