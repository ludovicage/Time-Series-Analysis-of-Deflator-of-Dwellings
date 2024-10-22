use "datastata_2024.dta"

log using Project.log, replace

*GENERO LE VARIABILI 
gen X=dvcft*(1+tiin)
gen X_=log(X)
gen X1= d.X_

gen X2_=log(nhpi)
gen X2= d.X2_

gen y1=log(diflab)
gen Y=d.y1


tsline Y X1 X2

/*PUNTO 3 -> GRAFICO DI OGNI VARIBAILE, E DELLA SUA FIRST DIFFERENCE */

tsset quarter, quarterly

*PLOT DELLA VARIABILE Y E DELTA_Y
tsline Y
tsline d.Y

*PLOT DELLA VARIABILE X1 E DELTA_X1
tsline X1
tsline d.X1

*PLOT DELLA VARIABILE X2 E DELTA_X2
tsline X2
tsline d.X2

********************************************************************************
*PUNTO 4 - CORRELOGRAMMI

ac Y
ac d.Y

*gli altri correlogrammi vengono presi da gretl 

*********************************************************************

*PUNTO 5 - ADF TEST

*Classical ADF test
dfuller Y, lags(4) regress
dfuller d.Y, lags(4) regress

dfuller X1, lags (4) regress
dfuller d.X1, lags (4) regress

dfuller X2, lags(4) regress
dfuller d.X2, lags(4) regress

*NOW we use the testing down procedure
ssc install adfmaxur

adfmaxur Y,maxlag(4)
adfmaxur d.Y, maxlag(4)


adfmaxur X1,maxlag(4)
adfmaxur d.X1, maxlag(4)

adfmaxur X2,maxlag(4)
adfmaxur d.X2, maxlag(4)

*********************************************************************
*PUNTO 6 -ARDL MODEL 
*ARDL/ESTIMATES BY HANDS (OLS OF DYNAMIC MODEL)

reg d.Y  dl(1/3).Y dl(0/3).X1  dl(0/3).X2 /*short-run*/ l.Y l.X1 l.X2 /*long-run*/ 

*CORRELOGRAMMA DEI RESIDUI
predict residuals, residuals
ac residuals, lags(24) // You can adjust the number of lags as needed

*WHITE
ssc install whitetst
whitetst
di ""

*ENGLE ARCH 
estat archlm

*NORMALITY 
sktest residuals
drop residuals




*DWATSON
estat dwatson

*GODFREY TEST
estat bgodfrey, lags(1 4 8)

*PSS F STATISTIC
testparm l.Y l.X1 l.X2

*t^2 static
testparm l.Y

*estimate long-run parametre
nlcom (b_y: _b[l.X1]/-_b[l.Y]) (b_pi: _b[l.X2]/-_b[l.Y]) , post



*the specialized ARDL block of commands 
ssc install dynardl 

*1- re estimate quietly the latter ardl 

reg d.Y  dl(1/3).Y dl(0/3).X1  dl(0/3).X2  l.Y l.X1 l.X2 
return list
ereturn list

*parametre settings 

local OBS = e(N)
display OBS

*2- compute

test l.Y
local TSTAT = -(r(F)^.5)
test l.Y l.X1 l.X2
local EFFE= r(F)
local KAPPA = r(df)-1

display EFFE
display KAPPA 
display TSTAT

*table of critical value 

/*pssbounds, fstat('EFFE') observations(207) case(3) k('KAPPA') tstat ('TSTAT')*/

pssbounds, fstat(9.3778668) observations(207) case(3) k(2) tstat (-5.1627015)

*intepreting the ARDL dynamics
*it firsts needs re-estimating the ardl 

*we now use new syntax, same ARDL model 

*shock X1
dynardl Y X1 X2, lags (1,1,1) diffs(.,1,1) lagdiffs (1/3, 1/3, 1/3) shockvar(X1) shockval(0.1) graph ec rarea time(120) range(150) change


*SHOCK X2
dynardl Y X1 X2, lags (1,1,1) diffs(.,1,1) lagdiffs (1/3, 1/3, 1/3) shockvar(X2) shockval(0.1) graph ec rarea time(120) range(150) change

**************************************************************************************
*POINT 7 

ssc install egranger

egranger Y X1 X2, lags (4) regress

*now we plot the residuals
tsline _egresid 



egranger Y X1 X2, lags (4)              ecm

* from the latter ecm estimate, restrict to zero some parameters
testparm dl.Y dl.X1 dl.X2 dl2.Y dl3.Y dl4.Y dl2.X1 dl3.X1 dl4.X1 dl2.X2 dl3.X2 dl4.X2

egranger Y X1 X2, lags (0)              ecm

log close













