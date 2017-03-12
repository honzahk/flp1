-- FIT VUTBR - FLP - project 1
-- Jan Kubis / xkubis13
import System.Environment
import System.Exit
import Control.Monad
import Data.Typeable --typeOf
import Data.List.Split --splitOn
import Data.List -- \\
import qualified Data.Set as Set
import Debug.Trace

import FaModule

debug = flip trace

helpText = "\nFIT VUTBR - FLP - project 1 - dka2mka\nauthor: Jan Kubis / xkubis13\nusage: ./dka2mka [ -i | -t ] [ FILE ]"
printHelp = putStrLn helpText

isArgsValid :: [[Char]] -> Bool
isArgsValid ["-t"] = True
isArgsValid ["-t",filename] = True
isArgsValid ["-i"] = True
isArgsValid ["-i",filename] = True
isArgsValid others = False

isArgsMinimize :: [[Char]] -> Bool
isArgsMinimize ["-t"] = True
isArgsMinimize ["-t",filename] = True
isArgsMinimize others = False

getArgsFilename :: [[Char]] -> [Char]
getArgsFilename [_,filename] = filename
getArgsFilename others = ""

getInput :: [Char] -> IO [Char]
getInput "" = getContents
getInput filename = readFile filename

--input: list of lines from user input
--output: KA tuple (Q,T,D,q0,F)
parseInput :: [[Char]] -> Fa
parseInput (l_states:l_init:l_final:l_trans) = Fa {
        fa_states=allStates,
        fa_alpha=validSymbols,
        fa_trans=allTrans,
        fa_init=initState,
        fa_fin=finStates,
        fa_nonFin= Set.difference allStates finStates
    }
    where   allStates = parseAllStates l_states
            allTrans = parseAllTrans l_trans
            initState = parseInitState l_init
            finStates = parseFinStates l_final

parseInput others = error "Invalid input!"

parseAllStates l_states = Set.fromList $ splitOn "," l_states
parseInitState l_init = l_init
parseFinStates l_final = Set.fromList $ splitOn "," l_final
parseAllTrans l_trans = map (\t->parseTrans t) l_trans
parseTrans t
    | length(exploded)/=3 = error "Invalid input!"
    | otherwise = Transition { tr_src=from, tr_sym=over,tr_dst=to}
    where   exploded = splitOn "," t
            from = exploded!!0
            over = exploded!!1
            to = exploded!!2


minimizeFa:: Fa -> IO()
minimizeFa fa = do--Fa {
--    fa_states= newStates,
--    fa_alpha= fa_alpha(fa),
--    fa_trans= [Transition{tr_src="a",tr_sym="b",tr_dst="c"}],
--    fa_init="i",
--    fa_fin= Set.fromList ["fin"],
--    fa_nonFin=  Set.fromList ["non-fin"]
--} where
    print $ hopcroft (Set.fromList [fa_fin fa, fa_nonFin fa]) (Set.singleton (fa_fin fa)) fa

hopcroft:: Set.Set(Set.Set State) -> Set.Set(Set.Set State) -> Fa -> Set.Set(Set.Set State)
hopcroft p w fa
    | (Set.size w)==0 = p
    | otherwise = hopcroft mod_p mod_w fa
                    where   (mod_p,(a,mod_w)) = hopcroftC (p,Set.deleteFindMin w) fa (fa_alpha fa)

-- p,w have to be in tuple - recursion (param type == ret type)
hopcroftC:: (Set.Set(Set.Set State),(Set.Set State,Set.Set(Set.Set State))) -> Fa -> Alphabet -> (Set.Set(Set.Set State),(Set.Set State,Set.Set(Set.Set State)))
hopcroftC (p,(a,w)) _ [] = (p,(a,w))
hopcroftC (p,(a,w)) fa (c:cs) = hopcroftC (modify_wp (p,(a,w)) fa c) fa cs --`debug` (show a ++ show p)

modify_wp:: (Set.Set(Set.Set State),(Set.Set State,Set.Set(Set.Set State))) -> Fa -> Symbol -> (Set.Set(Set.Set State),(Set.Set State,Set.Set(Set.Set State)))
modify_wp (p,(a,w)) fa c = (modify_p old_y mod_y x,(a,modify_w w mod_y x)) `debug` (show mod_y)
                            where   x = hopcroftX (fa_trans fa) c a
                                    mod_y = filterY p x
                                    old_y = Set.difference p mod_y

modify_p:: Set.Set(Set.Set State) -> Set.Set(Set.Set State) -> Set.Set State -> Set.Set(Set.Set State)
modify_p old_y mod_y x = Set.union old_y (replaceY mod_y x)

modify_w w mod_y x = Set.map cond mod_y
                        where cond y = if (elem y w)
                                        then setXor x y
                                        else    if (Set.size(Set.intersection x y) <= Set.size(Set.difference y x))
                                                then Set.intersection x y
                                                else Set.difference y x

-- careful, y \\ x !!!!
setXor:: Ord a => Set.Set a -> Set.Set a -> Set.Set a
setXor x y = Set.union (Set.intersection x y) (Set.difference y x)

filterY:: Set.Set(Set.Set State) -> Set.Set State -> Set.Set(Set.Set State)
filterY p x = Set.filter (\y->( not(null(Set.intersection x y)) && not(null(Set.difference y x)) )) p

replaceY:: Set.Set(Set.Set State) -> Set.Set State -> Set.Set(Set.Set State)
replaceY mod_y x = Set.union (Set.map (\y->Set.intersection x y) mod_y) (Set.map (\y->Set.difference y x) mod_y)

hopcroftX:: [Transition] -> Symbol -> Set.Set State -> Set.Set State
hopcroftX trans sym dsts = getMultTransSrc $ filterTransByMultDst dsts (filterTransBySym sym trans)

filterAllTransBySym:: Symbol -> Fa -> [Transition]
filterAllTransBySym sym fa = filterTransBySym sym (fa_trans fa)
filterTransBySym:: Symbol -> [Transition] -> [Transition]
filterTransBySym sym trans = filter (\t->(tr_sym t == sym)) trans

filterTransByMultDst:: Set.Set State ->  [Transition] -> [Transition]
filterTransByMultDst states trans = filter (\t->(elem (tr_dst t) states)) trans
filterTransByDst:: State -> [Transition] -> [Transition]
filterTransByDst state trans = filter (\t->(tr_dst t == state)) trans

getMultTransSrc:: [Transition] -> Set.Set State
getMultTransSrc trans = Set.fromList $ map (\t->(tr_src t)) trans

testf = (1,2)

main :: IO()
main = do
    argv <- getArgs
    when (not $ isArgsValid argv) $ error helpText

    input <- getInput $ getArgsFilename argv
    let fa = parseInput $ lines input
    when (not $ isFaValid fa) $ error "Invalid input!"
    --error "-------"
    if (isArgsMinimize argv) then do
        minimizeFa fa-- print $ fa_states $ minimizeFa fa
    else
        printFormatFa fa

    return ()