import Data.Char (isDigit, isSpace)
import Data.List (find, transpose)
import Data.Maybe (fromMaybe, mapMaybe)
import GHC.Base (VecElem (Int16ElemRep))
import GHC.Data.ShortText (ShortText (contents))
import System.Environment (getArgs)

main :: IO ()
main = do
  args <- getArgs
  case args of
    [filename] -> do
      result <- solve filename
      print result
    _ -> putStrLn "Provide input filename as only argument"

solve :: String -> IO (Int, Int)
solve filename = do
  fileContent <- readFile filename
  let homeworkLines = lines fileContent
  let part1Ans = part1 homeworkLines
  let part2Ans = part2 homeworkLines
  return (part1Ans, part2Ans)

-- ! PART 2:
part2 :: [String] -> Int
part2 xs =
  let cols = transpose xs
      blocks = splitOnEmpty cols
   in sum $ map processPart2Block blocks

-- >>> let cols = ["1  *","24  ","356 ","    ","369+","248 ","8   ","    "," 32*","581 ","175 ","    ","623+","431 ","  4 "]
-- >>> splitOnEmpty cols
-- [["1  *","24  ","356 "],["369+","248 ","8   "],[" 32*","581 ","175 "],["623+","431 ","  4 "]]
splitOnEmpty :: [String] -> [[String]]
splitOnEmpty [] = []
splitOnEmpty (x : xs)
  | all isSpace x = splitOnEmpty xs -- skip the columns where EVERYTHING is a space because thats the start of a new math operation
  | otherwise =
      let (operationBlock, rest) = break (all isSpace) (x : xs)
       in operationBlock : splitOnEmpty rest

-- >>> let blocks = [["1  *","24  ","356 "],["369+","248 ","8   "],[" 32*","581 ","175 "],["623+","431 ","  4 "]]
-- >>> processPart2Block <$> blocks
-- [8544,625,3253600,1058]
processPart2Block :: [String] -> Int
processPart2Block cols =
  let operator = fromMaybe '+' (find (`elem` "+*") (concat cols)) -- default to + but should never acutally happen
      opFunc = toOpChar operator
      nums = mapMaybe parseColNumber cols
   in foldl1 opFunc nums


parseColNumber :: String -> Maybe Int
parseColNumber col =
  let digits = filter isDigit col
   in if null digits then Nothing else Just (read digits)

toOpChar :: Char -> (Int -> Int -> Int)
toOpChar c = toOp $ c : ""

-- ! PART 1:
part1 :: [String] -> Int
part1 xs =
  let (nums, ops) = processInputPart1 xs
      transposeNums = transpose nums -- transpose is lazy so not too inefficient
      resultsPerCol = zipWith foldl1 ops transposeNums
   in sum resultsPerCol

processInputPart1 :: [String] -> ([[Int]], [Int -> Int -> Int])
processInputPart1 xs =
  let numericStrings = init xs
      opString = last xs
      nums = map parseNums numericStrings
      ops = parseOps opString
   in (nums, ops)

parseNums :: String -> [Int]
parseNums str = map read $ words str

parseOps :: String -> [Int -> Int -> Int]
parseOps str = map toOp $ words str

toOp :: String -> (Int -> Int -> Int)
toOp "+" = (+)
toOp "*" = (*)
toOp _ = (+) -- default plus, just assumethis doesn't happen


