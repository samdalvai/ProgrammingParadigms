module DatapointAggregation(
Point,
Rectangle,
boundingbox,
mindist,
nearestneighbors,
nondominated
)
where

-- Definition of types and list
type Point = (Double,Double)
type Rectangle = (Point,Point)

myDatapoints = [(2.3,5.4),(3.4,4.8),(6.3,9.4),(7.1,5.4),(1.1,8.5),(8.7,3.3),(9.3,2.3),(4.6,5.8),(7.6,4.9),(2.4,2.8),(3.9,1.1),(8.2,2.3),(4.4,7.2),(5.5,2.3),(9.1,9.8),(9.6,7.1)]

-- End of definitions

-- HASKELL ASSIGNMENT 
-- PROGRAMMING PARADIGMS COURSE 2020/21
-- STUDENT: SAMUEL DALVAI
-- ID: 17682 

--------------------------------------------------------------
-- Answer 1: points in a rectangle
--------------------------------------------------------------
boundingbox :: [Point] -> Rectangle -> [Point] 
boundingbox list rect = boundingboxAux list [] rect

-- Auxilliary function with accumulator to get a list of Points
-- fitting into a rectangle
boundingboxAux :: [Point] -> [Point] -> Rectangle -> [Point]
boundingboxAux [] temp rect = temp
boundingboxAux (h:t) temp rect 
    | (isInRectangle h rect) == True = boundingboxAux t (temp ++ [h]) rect
    | otherwise = boundingboxAux t (temp) rect

-- Auxilliary function to check if a Point is contained in a rectangle
-- if a Point resides on the edges of the rectangle (e.g. same x or y axis)
-- then it is not considered inside the rectangle
isInRectangle :: Point -> Rectangle -> Bool
isInRectangle a rect 
    | (isPointGreater a (getRectPointBottom rect)) && (isPointSmaller a (getRectPointUpper rect)) = True
    | otherwise = False

-- Auxilliary functions to get bottom left Point and upper right Point
-- of a rectangle 
getRectPointBottom :: Rectangle -> Point
getRectPointBottom (pb,pu) = pb

getRectPointUpper :: Rectangle -> Point
getRectPointUpper (pb,pu) = pu

-- Auxilliary function to confront two points, return True if the first point
-- is greater than the second, which means that it has greater values for the x
-- and y axis
isPointGreater :: Point -> Point -> Bool
isPointGreater a b 
    | (getX a) > (getX b) && (getY a) > (getY b) = True
    | otherwise = False

-- same as above but opposite
isPointSmaller :: Point -> Point -> Bool
isPointSmaller a b 
    | (getX a) < (getX b) && (getY a) < (getY b) = True
    | otherwise = False

-- Auxilliary functions to get distinct values from Point type
getX :: Point -> Double
getX (x,y) = x

getY :: Point -> Double
getY (x,y) = y

--------------------------------------------------------------
-- Answer 2: minimal Manhattan distance in a list of Points
--------------------------------------------------------------
mindist :: Point -> [Point] -> Double
mindist p list = mindistAux p list (manhattanDist p (head list))

-- Auxilliary method with accumulator to find the minimal
-- manhattan distance between a Point and a list of Points
-- Function has to be initialized elsewhere with the first 
-- manhattan distance of the list of Points
mindistAux :: Point -> [Point] -> Double -> Double
mindistAux p [] tempDist = tempDist
mindistAux p list tempDist
    | (manhattanDist p (head list)) < tempDist = mindistAux p (tail list) (manhattanDist p (head list))
    | otherwise = mindistAux p (tail list) tempDist

-- Get Manhattan distance between two points
manhattanDist :: Point -> Point -> Double
manhattanDist a b = absoluteValue((getX a) - (getX b)) + absoluteValue((getY a) - (getY b))

-- Auxilliary function to get absolute value of a number
absoluteValue :: Double -> Double
absoluteValue a =
    if a < 0 then (-1) * a
    else a

--------------------------------------------------------------
-- Answer 3: k nearest neighbors
--------------------------------------------------------------
nearestneighbors :: Point -> Int -> [Point] -> [Point]
nearestneighbors p k list = nearestneighborsAux p 0 k (length list) [] list

-- Auxilliary function with accumulator for k and max number of iterations regardless of k
nearestneighborsAux :: Point -> Int -> Int -> Int -> [Point] -> [Point] -> [Point]
nearestneighborsAux p index k max tempList mainList
    | index < k && index < max = nearestneighborsAux p (index+1) k max (tempList ++ [(nextNearestNeighbor p mainList)]) (removeNextNeighbor p mainList)
    | otherwise = tempList

-- remove the next nearest neighbor of a Point from a list od Points
removeNextNeighbor :: Point -> [Point] -> [Point]
removeNextNeighbor p list = (removePoint (nextNearestNeighbor p list) list)

-- get the next nearest neighbor of a Point in a list of points
nextNearestNeighbor :: Point -> [Point] -> Point
nextNearestNeighbor p list = (getManhattanPoint (mindist p list) p list)

-- get a Point in a list of Points based on a specific manhattan distance from a point
getManhattanPoint :: Double -> Point -> [Point] -> Point
getManhattanPoint dist p [] = (0,0)  --something went wrong
getManhattanPoint dist p list
    | dist == (manhattanDist p (head list)) = (head list)
    | otherwise = getManhattanPoint dist p (tail list)

-- remove first occurrence of a specific Point from a list of points
removePoint :: Point -> [Point] -> [Point]
removePoint p list = removePointAux p list []

removePointAux :: Point -> [Point] -> [Point] -> [Point]
removePointAux p [] tempList = tempList
removePointAux p list tempList
    | (equalPoint p (head list)) = removePointAux p [] (tempList ++ (tail list))
    | otherwise = removePointAux p (tail list) (tempList ++ [(head list)])

-- test if two points are equal
equalPoint :: Point -> Point -> Bool
equalPoint a b =
    if (getX a) == (getX b) && (getY a) == (getY b)
        then True
    else False

--------------------------------------------------------------
-- Answer 4: non dominated points of a given set of points.
--------------------------------------------------------------
nondominated :: [Point] -> [Point]
nondominated list = nondominatedAux list list []

-- Auxilliary function with accumulator, for each Point in the list of points
-- check if it is not dominated inside the list, if so add it to the temporary list
nondominatedAux :: [Point] -> [Point] -> [Point] -> [Point]
nondominatedAux mainList [] tempList = tempList
nondominatedAux mainList listCopy tempList
    | (isNotDominated (head listCopy) mainList) = nondominatedAux mainList (tail listCopy) (tempList ++ [(head listCopy)])
    | otherwise = nondominatedAux mainList (tail listCopy) tempList

-- returns True if there is no Point in the list of Points that
-- dominates Point p, otherwise False
isNotDominated :: Point -> [Point] -> Bool
isNotDominated a [] = True
isNotDominated a list 
    | (dominates (head list) a) = False
    | otherwise = isNotDominated a (tail list)

-- returns True if Point a dominates Point b
dominates :: Point -> Point -> Bool
dominates a b 
    | (getX a) < (getX b) && (getY a) < (getY b) = True
    | otherwise = False
