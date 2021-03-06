
{-# LANGUAGE FlexibleContexts #-}

module Initial where

import Control.Monad.Error (runErrorT)
import Control.Monad.State (execStateT)
import Data.Map (Map, fromList, empty)

import Core (scheme)
import Types.Core
import Types.Syntax

initialEnv :: Env
initialEnv = Global primitives

primitives :: Map Ident Expr
primitives = fromList
    [
    ]

initialLoad :: EnvRef -> IO Macro
initialLoad ref = execStateT (runErrorT $ runSchemeT $ scheme ref loadStr) empty
  where
    loadStr = concat $ map (\s -> "(load \"" ++ s ++ "\")")
        [ "lib/test.scm"
        , "lib/syntax.scm"
        , "lib/util.scm"
        ]
