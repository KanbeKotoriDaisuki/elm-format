module AST.Pattern where

import AST.V0_16
import qualified Reporting.Annotation as A


type Pattern ns =
    A.Located (Pattern' ns)


data Pattern' ns
    = Anything
    | UnitPattern Comments
    | Literal Literal
    | VarPattern LowercaseIdentifier
    | OpPattern SymbolIdentifier
    | Data ns UppercaseIdentifier [(Comments, Pattern ns)]
    | PatternParens (Commented (Pattern ns))
    | Tuple [Commented (Pattern ns)]
    | EmptyListPattern Comments
    | List [Commented (Pattern ns)]
    | ConsPattern
        { first :: WithEol (Pattern ns)
        , rest :: [(Comments, Comments, Pattern ns, Maybe String)]
        }
    | EmptyRecordPattern Comments
    | Record [Commented LowercaseIdentifier]
    | Alias (Pattern ns, Comments) (Comments, LowercaseIdentifier)
    deriving (Eq, Show, Functor)
