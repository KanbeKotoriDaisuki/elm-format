{-# LANGUAGE FlexibleInstances #-}

module AST.MapExpr where

-- NOTE: it's confusing about how this is meant to work:
-- is it meant to transform nodes and then recurse into them,
-- or to recurse into nodes and then transform them?
-- Try to avoid using this and use Functors / Data.Fix instead
-- (and hopefully remove this in the future).

import AST.V0_16
import AST.Expression
import AST.Pattern
import Data.Fix
import Reporting.Annotation


class MapExpr a where
    mapExpr :: (Expr' -> Expr') -> a -> a


instance MapExpr Expr where
    mapExpr f (Fix (LocatedExpression e)) = Fix $ LocatedExpression $ mapExpr f e


instance MapExpr (Located Expr') where
    mapExpr f (A region a) = A region (f a)


instance MapExpr e => MapExpr (IfClause e) where
    mapExpr f (IfClause cond body) = IfClause (mapExpr f cond) (mapExpr f body)


instance MapExpr a => MapExpr (PreCommented a) where
    mapExpr f (pre, a) = (pre, mapExpr f a)


instance MapExpr a => MapExpr (WithEol a) where
    mapExpr f = fmap (mapExpr f)


instance MapExpr a => MapExpr [a] where
    mapExpr f list = fmap (mapExpr f) list


instance MapExpr a => MapExpr (a, Bool) where
    mapExpr f (a, b) = (mapExpr f a, b)


instance MapExpr a => MapExpr (Commented Pattern, a) where
    mapExpr f (x, a) = (x, mapExpr f a)


instance MapExpr a => MapExpr (BinopsClause a) where
    mapExpr f (BinopsClause pre op post a) = BinopsClause pre op post (mapExpr f a)


instance MapExpr a => MapExpr (Commented a) where
    mapExpr f (Commented pre e post) = Commented pre (mapExpr f e) post


instance MapExpr a => MapExpr (Pair key a) where
    mapExpr f (Pair key value multi) = Pair key (mapExpr f value) multi


{-| NOTE: the function will never get applied to the parent Expr'; only on the first level of children -}
instance MapExpr e => MapExpr (Expression e) where
  mapExpr f expr =
    case expr of
        Unit _ -> expr
        AST.Expression.Literal _ -> expr
        VarExpr _ -> expr

        App f' args multiline ->
            App (mapExpr f f') (mapExpr f args) multiline
        Unary op e ->
            Unary op (mapExpr f e)
        Binops left restOps multiline ->
            Binops (mapExpr f left) (mapExpr f restOps) multiline
        Parens e ->
            Parens (mapExpr f e)
        ExplicitList terms' post multiline ->
            ExplicitList (mapExpr f terms') post multiline
        Range e1 e2 multiline ->
            Range (mapExpr f e1) (mapExpr f e2) multiline
        AST.Expression.Tuple es multiline ->
            AST.Expression.Tuple (mapExpr f es) multiline
        TupleFunction _ -> expr
        AST.Expression.Record b fs post multiline ->
            AST.Expression.Record b (mapExpr f fs) post multiline
        Access e field' ->
            Access (mapExpr f e) field'
        AccessFunction _ -> expr
        Lambda params pre body multi ->
            Lambda params pre (mapExpr f body) multi
        If c1 elseIfs els ->
            If (mapExpr f c1) (mapExpr f elseIfs) (mapExpr f els)
        Let decls pre body ->
            Let (mapExpr f decls) pre body
        Case cond branches ->
            Case (mapExpr f cond) (mapExpr f branches)
        GLShader _ -> expr


instance MapExpr e => MapExpr (LetDeclaration e) where
    mapExpr f d =
        case d of
            LetDefinition name args pre body -> LetDefinition name args pre (mapExpr f body)
            _ -> d
