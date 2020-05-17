module AST.MatchReferences (MatchedNamespace(..), fromMatched, matchReferences, applyReferences) where

import AST.V0_16
import AST.Structure
import Control.Applicative ((<|>))
import Data.Coapplicative
import ElmFormat.ImportInfo (ImportInfo)

import qualified Data.Bimap as Bimap
import qualified Data.Map.Strict as Dict
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified ElmFormat.ImportInfo as ImportInfo


data MatchedNamespace t
    = NoNamespace
    | MatchedImport Bool t -- Bool is True if it was originally qualified
    | Unmatched t
    deriving (Eq, Ord, Show, Functor)


fromMatched :: t -> MatchedNamespace t -> t
fromMatched empty NoNamespace = empty
fromMatched _ (MatchedImport _ t) = t
fromMatched _ (Unmatched t) = t


matchReferences ::
    (Coapplicative annf, Ord u) =>
    ImportInfo [u]
    -> ASTNS annf [u] kind
    -> ASTNS annf (MatchedNamespace [u]) kind
matchReferences importInfo =
    let
        aliases = Bimap.toMap $ ImportInfo._aliases importInfo
        imports = ImportInfo._directImports importInfo
        exposed = ImportInfo._exposed importInfo

        f locals ns identifier =
            case ns of
                [] ->
                    case Dict.lookup identifier locals of
                        Just () -> NoNamespace
                        Nothing ->
                            case Dict.lookup identifier exposed of
                                Nothing -> NoNamespace
                                Just exposedFrom -> MatchedImport False exposedFrom

                _ ->
                    let
                        self =
                            if Set.member ns imports then
                                Just ns
                            else
                                Nothing

                        fromAlias =
                            Dict.lookup ns aliases

                        resolved =
                            fromAlias <|> self
                    in
                    case resolved of
                        Nothing -> Unmatched ns
                        Just single -> MatchedImport True single

        defineLocal name = Dict.insert name ()

        mapTypeRef locals (ns, u) = (f locals ns (TypeName u), u)
        mapCtorRef locals (ns, u) = (f locals ns (CtorName u), u)
        mapVarRef locals (VarRef ns l) = VarRef (f locals ns (VarName l)) l
        mapVarRef locals (TagRef ns u) = TagRef (f locals ns (CtorName u)) u
        mapVarRef _ (OpRef op) = OpRef op
    in
    topDownReferencesWithContext
        defineLocal
        mapTypeRef mapCtorRef mapVarRef
        mempty


applyReferences ::
    (Coapplicative annf, Ord u) =>
    ImportInfo [u]
    -> ASTNS annf (MatchedNamespace [u]) kind
    -> ASTNS annf [u] kind
applyReferences importInfo =
    let
        aliases = Bimap.toMapR $ ImportInfo._aliases importInfo
        exposed = ImportInfo._exposed importInfo
        unresolvedExposingAll = ImportInfo._unresolvedExposingAll importInfo

        f locals ns' identifier =
            case ns' of
                NoNamespace -> []
                MatchedImport wasQualified ns ->
                    let
                        qualify =
                            case wasQualified of
                                True ->
                                    (Dict.lookup identifier exposed /= Just ns) -- it's not exposed
                                    || Dict.member identifier locals -- something is locally defined with the same name
                                    || unresolvedExposingAll -- there's an import with exposing(..) and we can't be sure if something exposed by that would conflict
                                False -> False -- never add qualification to something that was not qualified
                    in
                    if qualify
                      then Maybe.fromMaybe ns $ Dict.lookup ns aliases
                      else [] -- This is exposed unambiguously and doesn't need to be qualified
                Unmatched name -> name

        defineLocal name = Dict.insert name ()

        mapTypeRef locals (ns, u) = (f locals ns (TypeName u), u)
        mapCtorRef locals (ns, u) = (f locals ns (CtorName u), u)
        mapVarRef locals (VarRef ns l) = VarRef (f locals ns (VarName l)) l
        mapVarRef locals (TagRef ns u) = TagRef (f locals ns (CtorName u)) u
        mapVarRef _ (OpRef op) = OpRef op
    in
    topDownReferencesWithContext
        defineLocal
        mapTypeRef mapCtorRef mapVarRef
        mempty
