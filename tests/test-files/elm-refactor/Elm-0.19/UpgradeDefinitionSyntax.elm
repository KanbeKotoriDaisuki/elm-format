module UpgradDefinitionSyntax exposing (x)

import A
import B exposing (OldType)


x =
    ()


values =
    [ A.value
    , A.lambda
    , A.lambda 1
    , A.lambda 2 3
    , A.lambda 4 5 6
    , A.function
    , A.function 7
    , A.function 8 9
    , A.function 10 11 12
    ]


tags =
    [ A.Tag
    , A.Tag2
    , A.Tag2 100
    , A.Tag2 101 102
    , A.Tag2 103 104 105
    ]


cases s =
    [ A.caseExhaustive ()
    , A.caseWithPattern Nothing
    , A.caseWithPattern (Just 13)
    , A.caseWithPattern (Just <| (+) 14 15)
    , A.caseWithPattern (Just <| 16 + 17)
    , A.caseWithPattern (Just <| identity <| 18 + 19)
    , A.caseWithWildcard Nothing
    , A.caseWithWildcard (Just ())
    , A.caseWithAsMatch { style = A.Style1 }
    , A.caseWithAsMatch { style = UnknownStyle }
    , A.caseWithAsMatch { style = s }
    ]


typeChange :
    A.Type Int String
    -> OldType {} Never
    -> ()
typeChange _ _ =
    ()
