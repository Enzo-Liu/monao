
module Field (
	Field,
	loadField,
	fieldRef,
	isBlock,
	renderField
) where

import Multimedia.SDL

import Const
import Util

type Cell = Char
type Field = [[Cell]]


-- マップ

-- マップ読み込み
loadField :: Int -> IO Field
loadField stage = readFile fn >>= return . lines
	where
		fn = "data/stage" ++ (show stage) ++ ".map"


chr2img '@' = ImgBlock1
chr2img 'O' = ImgBlock2
chr2img 'X' = ImgBlock3
chr2img '?' = ImgBlock4
chr2img '_' = ImgMt02
chr2img '/' = ImgMt11
chr2img ',' = ImgMt12
chr2img '\\' = ImgMt13
chr2img '.' = ImgMt22
chr2img '1' = ImgCloud00
chr2img '2' = ImgCloud01
chr2img '3' = ImgCloud02
chr2img '4' = ImgCloud10
chr2img '5' = ImgCloud11
chr2img '6' = ImgCloud12
chr2img '7' = ImgGrass00
chr2img '8' = ImgGrass01
chr2img '9' = ImgGrass02
chr2img '[' = ImgDk00
chr2img ']' = ImgDk01
chr2img 'l' = ImgDk10
chr2img '|' = ImgDk11

chr2img '!' = ImgDk11
chr2img 'o' = ImgDk11


isBlock :: Cell -> Bool
isBlock c = c `elem` "@OX?[]l|"

inField :: Field -> Int -> Int -> Bool
inField fld x y = 0 <= y && y < length fld && 0 <= x && x < length (fld !! y)

fieldRef :: Field -> Int -> Int -> Cell
fieldRef fld x y
	| inField fld x y	= fld !! y !! x
	| otherwise			= ' '


renderField sur imgres scrx fld =
	sequence_ $ concatMap lineProc $ zip [0..] fld
	where
		lineProc (y, ln) = map (cellProc y) $ zip [0..] $ window ln
		cellProc _ (_, ' ') = return ()
		cellProc y (x, c) = putchr x y c >> return ()
		putchr x y c = blitSurface (getImageSurface imgres $ chr2img c) Nothing sur $ pt (x*chrSize - rx) (y*chrSize)

		-- 表示される部分だけ取り出す
		window = take w . drop qx
		qx = scrx `div` chrSize
		rx = scrx `mod` chrSize
		w = 256 `div` chrSize + 1
