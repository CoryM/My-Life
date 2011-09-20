#COMPILE EXE
#DIM ALL

'Constants
%False = 0
%True = NOT %False

'only works for ranges of minvalue-1 to maxvalue+1
MACRO WrapValue (outvalue, invalue, minvalue, maxvalue)
    IF invalue < minvalue THEN
        outvalue = maxvalue
    ELSEIF invalue > maxvalue THEN
        outvalue = minvalue
    ELSE
        outvalue = invalue
    END IF
END MACRO

TYPE RGBA
    red AS BYTE
    green AS BYTE
    blue AS BYTE
    alpha AS BYTE
END TYPE

UNION colorspace
    rgbColor AS DWORD
    rgba AS rgba
END UNION

TYPE Vector2
    X AS LONG
    Y AS LONG
END TYPE

TYPE LifeStats
    Life AS BYTE
    Food AS BYTE
END TYPE

FUNCTION PBMAIN () AS LONG
    LOCAL wSize AS Vector2'             Window info
    LOCAL wPos AS Vector2
    LOCAL hWin AS DWORD

    LOCAL FoodSeed AS LONG'             Odds for a dot to have a food added.
    LOCAL CountDown AS LONG'            How meny dots until next dot has food added to it.
    LOCAL Change AS LONG'               Has the current dot changed?
    LOCAL Colors AS ColorSpace'         If so what color has it changed to.
    LOCAL LifeCount AS LONG'            Current total population
    LOCAL Generation AS LONG'           Number of times the loop has been processed
    LOCAL DataWork() AS LifeStats'      The new State of everything
    LOCAL DataSource() AS LifeStats'    Current state of everything

    LOCAL MinScan AS Vector2'           Min and Max postions to scan for local population count
    LOCAL MaxScan AS Vector2
    LOCAL NearLifeCount AS LONG'        local population count

    LOCAL AutoLifeMinGen AS LONG
    LOCAL AutoLifeMinPop AS LONG
    LOCAL AutoLifeRegen AS LONG
    LOCAL AutoLifeStatus AS LONG'       Was there an autogen event in this loop, if so display status

    LOCAL tmp1x AS LONG'                scatchpad varibles
    LOCAL tmp1y AS LONG
    LOCAL tmp2x AS LONG'                scratchpad varibles defined as long because vector2 errors
    LOCAL tmp2y AS LONG'                when used as "FOR tmp1.x=0 TO 10" with "Numeric scalar varible expected"
    LOCAL tmp3x AS LONG
    LOCAL tmp3y AS LONG
    LOCAL var1 AS LONG

    LOCAL Done AS LONG'                 Is the loop done?


    RANDOMIZE TIMER

    wSize.X = 511'          Size of Window and world
    wSize.Y = 511
    FoodSeed = 11'          How often to add some food to a dot in the world. (Hight number = Lower odds, 2=50% chance, 4=25% chance)
    AutoLifeMinGen = 700'   AutoLife until we are above this generation
    AutoLifeMinPop = 13000' AutoLife until we are more then this population
    AutoLifeRegen = 10'     How meny to add to the population per round until MinGen and MinPop are met.

    'Create and center graphic window
    DESKTOP GET SIZE TO tmp1x, tmp1y
    GRAPHIC WINDOW "Life Gen", (tmp1x-wSize.X)/2, (tmp1y-wSize.Y)/2 , wSize.X+1, wSize.Y+1 TO hWin
    GRAPHIC ATTACH hWin, 0, REDRAW

    DIM DataSource(wSize.X, wSize.Y) AS LifeStats
    DIM DataWork(wSize.X, wSize.Y) AS LifeStats

    DO WHILE Done=0
        GRAPHIC INSTAT TO Done
        IF ISWIN(hWin) = %False THEN EXIT DO

        LifeCount=0

        'Copy DataWork to DataSource
        'An ARRAY COPY command would be nice here .. cough cough
        FOR tmp1y = 0 TO wSize.Y
            FOR tmp1x = 0 TO wSize.X
                DataSource(tmp1x, tmp1y) = DataWork(tmp1x, tmp1y)
            NEXT tmp1x
        NEXT tmp1y


        FOR tmp1y = 0 TO wSize.Y
            FOR tmp1x = 0 TO wSize.X
                change=%false
                'Is there food?
                IF DataSource(tmp1x, tmp1y).Food>2 THEN
                    'Is there life already here?
                    IF DataSource(tmp1x, tmp1y).Life = 0 THEN
                        'No life but food check for nearby life
                        IF tmp1x=0 OR tmp1x=wSize.X  OR tmp1y = 0 OR tmp1y = wSize.Y THEN
                            'Slower scan around edges
                            MinScan.X=tmp1x-1
                            MinScan.Y=tmp1y-1
                            MaxScan.X=tmp1x+1
                            MaxScan.Y=tmp1y+1
                            NearLifeCount=0
                            FOR tmp2y = MinScan.Y TO MaxScan.Y
                                WrapValue (tmp3y, tmp2y, 0, wSize.Y)
                                FOR tmp2x = MinScan.X TO MaxScan.X
                                    WrapValue (tmp3x, tmp2x, 0, wSize.X)
                                    IF DataSource(tmp3x, tmp3y).Life > 0 THEN NearLifeCount += 1
                                NEXT tmp2x
                            NEXT tmp2y
                        ELSE
                            'faster scan with no edges
                            MinScan.X=tmp1x-1
                            MaxScan.X=tmp1x+1
                            NearLifeCount=0
                            FOR tmp2y = tmp1y+1 TO tmp1y-1 STEP -1
                                FOR tmp2x = MaxScan.X TO MinScan.X STEP -1
                                    IF DataSource(tmp2x, tmp2y).Life > 0 THEN NearLifeCount += 1
                                NEXT tmp2x
                            NEXT tmp2y
                        END IF

                        'If theres life near then multiply
                        IF NearLifeCount => 2 THEN DataWork(tmp1x, tmp1y).Life = 1
                        'IF NearLifeCount > 0  THEN Life(tmp1x, tmp1y, DataWork) = 1
                    END IF
                END IF
            NEXT tmp1x
        NEXT tmp1y

        CountDown = INT(RND(1, FoodSeed))
        FOR tmp1y = 0 TO wSize.Y
            FOR tmp1x = 0 TO wSize.X
                'is there life? (update food)
                IF DataSource(tmp1x, tmp1y).Life = 0 THEN
                    'No life here update food to +1 max of 15
                    IF CountDown = 0 THEN
                        DataWork(tmp1x, tmp1y).Food = MIN(DataSource(tmp1x, tmp1y).Food + 1, 255)
                        CountDown = INT(RND(1, FoodSeed))
                        change=%true
                    ELSE
                        CountDown -= 1
                        change=%False
                    END IF
                ELSE
                    LifeCount += 1
                    'Theres life update food to -1 min of 0
                    var1 = DataSource(tmp1x, tmp1y).Food
                    IF var1<=0 THEN DataWork(tmp1x, tmp1y).Life = 0 ELSE DataWork(tmp1x, tmp1y).Life += 1
                    DataWork(tmp1x, tmp1y).Food = MAX(var1-DataSource(tmp1x, tmp1y).Life,0)
                    'Ran out of food life straved, set life to 0
                    Change=%true
                END IF
                IF Change THEN
                    Colors.rgba.red = MIN(DataWork(tmp1x, tmp1y).Life*32, 255)
                    Colors.rgba.green = MIN(DataWork(tmp1x, tmp1y).Food*7, 255)
                    Colors.rgba.blue = DataWork(tmp1x, tmp1y).Food * DataWork(tmp1x, tmp1y).Life
                    GRAPHIC SET PIXEL (tmp1x, tmp1y), Colors.rgbColor
                END IF

            NEXT tmp1x
        NEXT tmp1y

        'See if we need to seed the map?
        IF Generation =< AutoLifeMinGen OR LifeCount =< AutoLifeMinPop THEN
            FOR var1=0 TO AutoLifeRegen
                tmp1x=INT(RND(0,wSize.X-1))
                tmp1y=INT(RND(0,wSize.Y-1))
                DataWork(tmp1x, tmp1y).Life = 1
                DataWork(tmp1x+1, tmp1y+1).Life = 1
                DataWork(tmp1x+1, tmp1y).Life = 1
            NEXT var1
            AutoLifeStatus = %True
        ELSE
            AutoLifeStatus = %False
        END IF

        Generation += 1
        'Update stats on the window title bar.
        DIALOG SET TEXT hWin, USING$("Life Population: ###,###  Generation: ###,### &",LifeCount, Generation, IIF$(AutoLifeStatus, "AutoLife", ""))
        GRAPHIC REDRAW

    LOOP

    GRAPHIC WINDOW END

END FUNCTION
