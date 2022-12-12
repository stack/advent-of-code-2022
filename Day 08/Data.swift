//
//  Data.swift
//  Day 08
//
//  Created by Stephen H. Gerstacker on 2022-12-08.
//  SPDX-License-Identifier: MIT
//

import Foundation

let SampleData = """
30373
25512
65332
33549
35390
"""

let InputData = """
131102031022411233124153000402524132243245422402002121234345453535321113450535302430144220243210033
210030011133442111442145434004231353202400601331445042106230540242340014332243105022302133441101011
201302044230110302341330012044051130055046354663404014033243655520410125432425532024143403330032232
210303103204034020151134514120046162664361356330261302226530654326452225134535222440444443410101130
021310332113230035544033314213544254421233042151226601345516101654005025035545035333140023212102212
220140301231432453044535532323066560244052510442522465306425021511260132313424322110345422300411332
103013240142011245425311001542145655516105003352455141424412415222100145355043202120423034202120403
314103304322445325255534650156565303510461206034672755654106425161056213552330050310445352323213402
243430113305332145305400366156126611120357766767667531265661631510215134106224240155532142014202020
344044011305120500223111213354316112154646744635155132374774442641061323024416155344101304242413014
210001340311202411013214565026366577746364242672331436164352252445110000414212215202321411504422400
001030344254033552521244445311464542617442572153467545366653342426676363026234406640015310103000111
123004351234415456501532136126535464236513321263256111263236363424471316560661104630322511135024314
243444301010130503501065440067414335615573435151661324666436573133444251763541254166141130405531401
301333054435342646553265615125271561444757162666247563564724434377461174733226461663122454115301022
313333115034033032461152521554721624436564356545874583322623147632365263427634464233444421123452114
434441324240044110131332722354256132333522657745624745724323263635746316535120231124164652542245541
020013043025261604606066777717675561448878622688884553346728286853164272251311263510330645452212040
225405401530036646635664123763243188844858643328244728344354343287813231363771264361344552214134043
444013205241103641532477643143435563484567276423226466226434857664377176552653732212146514023430325
235444033555452351644577725572733823223422438445886848336238372267477767173715122521014452405344110
022222500504231055646646534633724257646568684735488756288737857786232268232655151633323530463425151
412102254551210100735562467375656382325864659764674335534465738553284326347575542675435335613154320
202304233522424114651647265763556544532358373769578879369385574555386666783363244334360301665155255
400235422666401262236327746826382638573848989589958764697958946664233887757677777164614616200413302
413211350405512664175712772346875822558798479568486643787487763573785465875336133314155235265153544
412112650043523364626154522655787734369585968849884958638795656846722736645822544573361050432101002
040151232015244534675233447267274466883354564933934639355395374945757347634723116764261154205631025
053511566106055552733487866435428673379594867554589579573759867856436754328455243315565403452366550
402441261342655261311663778728277373873487457867467678497684746937764462833722831553364205512206541
401560462601374333165687778774966694644847875679669694796453568554383377242683474675113640166014002
245431640441276372256235534578677594558499466595957658548574676357557473852362834636123725105611001
140325466637452621767678632447835458776865576466546548894776445753494487385328422645157221103664133
253440020224216474125727543697395446885846849486744757588954688447585337348374328857266123303626032
522360463154354425644334277863647479565896696996775849896649575745746557964548536537415577142552050
402351634474624167474857559553949899894799879644496759587555549787974996993634823833353424316316042
414140006077774645384224689955449865767867876647679668857949995687773539976755288762714471242526254
032242255462211412258653836566746764685477947565799869886769647489953985859547537844111624535631156
241646435225236526565228495485878686676559956669957869665758947786478934645637286347261114426145563
512215356337536722737525437473645894558456658976958699776986594778559569864962457825216143344215016
322625244746336257345525895486859454957989669585766859958667775649875866654855238722721513671212305
044600535247217686848675385837958687859856856865869679556868995579875763985654342678317263541605554
430320424173321746345287493633447589689698796959599858768985856685945573454358785585284454656334025
232026013361136674773333583555589876467998965697988698997966777468454666855894285223681327425505166
354332536226232536453676489538955896788985786767799998876886965757444485955456462568453444425456521
016154147271566788586769489946847647867857556667888797775895768988576579978395627453672756147414326
463454162462563733454784956555887864475857986666689767978699985965647598648778424456255355723655466
021001072567511684363734454496747746785559778677966778897776558954997794766634668356686124441524525
234605435156344755776859794859864756797769876888968689787579998559856654953446748662382433262116262
030666223611312438477278595797684446757958596668696976678757986797965899875556377876865147373650335
245046541536764737224694794369857786796969878968689968797958865856864988656773724353268427134461620
265066622261247542566375373496969757789659688887789988798956868878668565665794723743572475263161166
422245453144736877586299945587888888767997586686876996879786788998867747683776448657845662361505315
210351625547722865278485967857788659769765586689699988976775596895984657648869967252632246417436621
141004614422116428487735355858968995455599988699767679796595755979678769336598642342483777532511004
533362561377622426377686383498446767487997987976886899988585956569875694463399574483265564264622314
456163507723454276868637866355647859456998677889778989889969998954684957667483346372863274465245646
030644251421316636263479555487765499846688669798677798668968599994746869757876565775844144255106462
510135336311735337436764935399965949469956999767696876898578576969547984463869253278467243311543030
466524526117724766584368696865578944888566858759789698699778689456856774865884337672615767136523254
254110631463762333865539645936466585858655857657659586556989585456479575455563845762632676471423233
562434653773762262468663566995359545869887797866957588766855659579865834576343438465353323754454240
112066240641477224475587449447989749648974898785555767886979489566644938356955638286634724441631625
330443313353347713822865768695549469777556759786896565758769775757475566378642426537546311412140051
040065350247621726448577745444446666557767548565886798996759654466566755698345662584625446342463260
330536625076531353825376746548345995946649894668956867559446757474398638639624464682343654214032311
530251120326432762683357643388548466489576697998869899549584977659746869733837538723573545213461105
255356015316555756432734833639785737748988987965669458947565666746847669548847254811135737404226043
454354550123557227257454326863468487794448666674495859497588676766356646553276336612337324063553462
144340525160235512164242786385886753536996894579865659848488534457479379684556654637432614663443613
305316054035171372138527636345993984687638579458566486795488343446895753373444445772513544116215313
543055400456632262131666826787874497775946535566897457748984377394483964377555447341647525602315351
412546632444321676125286364645444448636496473746537653585847369856994564666782226566264742530022340
044233444612165527122563533685825959374668734768758953663536843946435452847223172365277563546141540
340030454102343151253211647666557354334348799955649644348678747758347287426221514313112316663165454
011020051334501654522762446268866586389746656669789443696677886848328248582411315534364123146250501
305413453334030464614216442476475733478966457359966737766476988846463467574624373625606065562242335
034215112203016427473135421577622448726677469646375339565639944867546662453345521671403262325021214
132210543140531252452317342463454885388566728556533533877354846446665578244115675240031664244524501
201140051634662646614612354714626525722377445426842485568735384726362363654642742661135663265002510
025011353243541235316415314133578633558245363633567643474723462264656821637416273202656565602515322
121540314222665224011553176734444466578255884322834667368468238484254776573264467333645106223352155
233134314541654641520531771126551528746557387438726348653238283875537147555615754035502132555444301
424510000505066600303343337525732714723283556468834467558232644677477536766533666404266150255104242
041433452552331436330125237255465337374884372735358382327855756643676341445255435062065033314033212
141025211241314363206626056633223121353133645783244374622462256271457773212200625560321421020100213
224101010422251643133220616233621223532466525114754865347141165612135423157400060111225313054434032
004040052225144131342364656025377722754756627621767354111575442445436452322335541156250421012350243
043322120521041516241540153402233524371432721521521276133447761312616332565246332656140342120501432
200232013354533102134562014146621725413251577715376671261144475237357064044430050234040121014304202
011420212054031401033241133121106532344212712314572323662643147467661343340045361122545415103011124
102223410325432324313243446514164004156475643254444557477323147134144354265066260422110450012141414
031411112311321035125554420606413626050373327654774373667767140605036115333551650220414205214132024
210204032200320524351051665115025502044361230251377575706601164652440120455165201034431244211004301
331131223444034015143142430503454436431142412165246111316106164251614223504203533022310134023423343
120300034332102045152234220042512653414152606411234665213124345325420542210314454221024423343223220
200230420442302210441134513143532363040132120013505235035543064245636124512505054404233133430423011
000202411243122420140310501035333204626352325031215630345206242502134153000033354044334042221310101
111301302244231442013332415144033330063530643146335532313306033656410450441505505240142210004121122
"""
