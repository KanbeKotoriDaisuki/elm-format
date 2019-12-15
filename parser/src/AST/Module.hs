{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE StandaloneDeriving #-}

module AST.Module
    ( Module(..), Header(..), SourceTag(..), SourceSettings
    , UserImport, ImportMethod(..)
    , DetailedListing(..)
    , defaultHeader
    , BeforeExposing, AfterExposing, BeforeAs, AfterAs
    ) where

import AST.Declaration (TopLevelStructure)
import AST.Structure
import qualified AST.Variable as Var
import qualified Cheapskate.Types as Markdown
import Data.Map.Strict (Map)
import qualified Reporting.Annotation as A
import AST.V0_16


-- MODULES


data BeforeImports
data Module ns decl =
    Module
    { initialComments :: Comments
    , header :: Maybe Header
    , docs :: A.Located (Maybe Markdown.Blocks)
    , imports :: C1 BeforeImports (Map ns (C1 Before ImportMethod))
    , body :: [TopLevelStructure decl]
    }
    deriving (Eq, Show)

instance (Functor ann, ChangeAnnotation decl ann) => ChangeAnnotation (Module ns (ann decl)) ann where
    type SetAnnotation ann' (Module ns (ann decl)) = Module ns (ann' (SetAnnotation ann' decl))
    convertFix f mod = mod { body = fmap (fmap $ f . (fmap $ convertFix f)) (body mod) }


-- HEADERS

data SourceTag
  = Normal
  | Effect Comments
  | Port Comments
  deriving (Eq, Show)


{-| Basic info needed to identify modules and determine dependencies. -}
data BeforeWhere; data AfterWhere
data Header = Header
    { srcTag :: SourceTag
    , name :: C2 Before After [UppercaseIdentifier]
    , moduleSettings :: Maybe (C2 BeforeWhere AfterWhere SourceSettings)
    , exports :: Maybe (C2 BeforeExposing AfterExposing (Var.Listing DetailedListing))
    }
    deriving (Eq, Show)


defaultHeader :: Header
defaultHeader =
    Header
        Normal
        (C ([], []) [UppercaseIdentifier "Main"])
        Nothing
        Nothing


data BeforeListing
data DetailedListing = DetailedListing
    { values :: Var.CommentedMap LowercaseIdentifier ()
    , operators :: Var.CommentedMap SymbolIdentifier ()
    , types :: Var.CommentedMap UppercaseIdentifier (C1 BeforeListing (Var.Listing (Var.CommentedMap UppercaseIdentifier ())))
    }
    deriving (Eq, Show)

instance Semigroup DetailedListing where
    (DetailedListing av ao at) <> (DetailedListing bv bo bt) = DetailedListing (av <> bv) (ao <> bo) (at <> bt)

instance Monoid DetailedListing where
    mempty = DetailedListing mempty mempty mempty


type SourceSettings =
  [(C2 Before After LowercaseIdentifier, C2 Before After UppercaseIdentifier)]

-- IMPORTs

type UserImport
    = (C1 Before [UppercaseIdentifier], ImportMethod)


data BeforeAs; data AfterAs; data BeforeExposing; data AfterExposing
data ImportMethod = ImportMethod
    { alias :: Maybe (C2 BeforeAs AfterAs UppercaseIdentifier)
    , exposedVars :: C2 BeforeExposing AfterExposing (Var.Listing DetailedListing)
    }
    deriving (Eq, Show)
