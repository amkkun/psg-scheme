{-# LANGUAGE FlexibleContexts #-}

module Parser where

import Control.Applicative ((<|>), (<$>), (<*>), (*>), (<*))
import Control.Comonad (($>))
import Control.Exception.Lifted (throwIO)
import Control.Monad.Base (MonadBase)
import Data.Char (toLower)
import Data.Monoid (mempty)
import Text.Trifecta hiding (parseString, doc)
import qualified Text.Trifecta as T

import Types.Exception
import Types.Syntax.Before
import Types.Util

parse :: MonadBase IO m => String -> m Expr
parse str = case T.parseString parseExpr mempty str of
    Success expr -> return expr
    Failure doc -> throwIO $ ParseError doc

parseExpr :: Parser Expr
parseExpr = between spaces spaces $
    parseConst <|>
    parseList <|>
    parseQuote <|>
    parseIdent

parseConst :: Parser Expr
parseConst = Const <$> (parseBool <|> parseNumber <|> parseString)

parseBool :: Parser Const
parseBool = parseTrue <|> parseFalse
  where
    parseTrue = symbol "#t" $> Bool True
    parseFalse = symbol "#f" $> Bool False

parseNumber :: Parser Const
parseNumber = try . token $ Number <$>
    integer' <* notFollowedBy identChar

parseString :: Parser Const
parseString = try $ String <$> stringLiteral

parseList :: Parser Expr
parseList = List <$> (parseProperList <|> parseDottedList)

parseProperList :: Parser (List Expr)
parseProperList = try . parens $
    ProperList <$> many parseExpr

parseDottedList :: Parser (List Expr)
parseDottedList = try . parens $ DottedList <$>
    some parseExpr <* symbol "." <*> parseExpr

parseQuote :: Parser Expr
parseQuote = List . ProperList <$>
    (two <$> (symbol "'" $> Ident "quote") <*> parseExpr)
  where
    two x y = [x, y]

parseIdent :: Parser Expr
parseIdent = Ident . map toLower <$> (
    notFollowedBy (Ident <$> symbol "." <|> Const <$> parseNumber) *>
    token (some identChar)
    )

identChar :: Parser Char
identChar = alphaNum <|> oneOf "!$%&*+-./<=>?@^_"
