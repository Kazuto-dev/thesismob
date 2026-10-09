// ignore_for_file: prefer_const_constructors, duplicate_ignore, unused_import

//main components
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesismob/frames/Mains/sheetProvider.dart';
import 'package:thesismob/frames/Mains/sheetForm.dart';
import 'package:thesismob/frames/Mains/mainpage.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';
import 'package:thesismob/frames/Mains/calculationHIstory.dart';
import 'package:thesismob/frames/Mains/DisplayHistory.dart';
import 'package:thesismob/frames/Mains/TableSummary.dart';
import 'package:thesismob/frames/Mains/summaryClass.dart';
import 'package:thesismob/frames/Mains/summaryHistory.dart';
import 'package:thesismob/frames/Mains/structuralpages.dart';
import 'package:thesismob/frames/Mains/archpages.dart';
import 'package:thesismob/frames/Mains/electricalPages.dart';
import 'package:thesismob/frames/Mains/plumbingPages.dart';

//Pages
import 'package:thesismob/frames/Mains/MainMenu.dart';
import 'package:thesismob/frames/Mains/Instructions.dart';

import 'package:thesismob/frames/Materials/CHB/CHBpages.dart';
import 'package:thesismob/frames/Materials/CHB/CHB.dart';
import 'package:thesismob/frames/Materials/CHB/Solutions.dart';
import 'package:thesismob/frames/Materials/CHB/DoF.dart';
import 'package:thesismob/frames/Materials/Carpet/CarpetDef.dart';
import 'package:thesismob/frames/Materials/Carpet/CarpetSol.dart';

import 'package:thesismob/frames/Materials/Tiles/DoFTiles.dart';
import 'package:thesismob/frames/Materials/Tiles/SolutionTiles.dart';
import 'package:thesismob/frames/Materials/Tiles/tiles.dart';
import 'package:thesismob/frames/Materials/Tiles/tilesPages.dart';

import 'package:thesismob/frames/Mains/Architectural.dart';
import 'package:thesismob/frames/Mains/Electrical.dart';
import 'package:thesismob/frames/Mains/Plumbing.dart';
import 'package:thesismob/frames/Mains/Structural.dart';

import 'package:thesismob/frames/Materials/Plywood/plywoodDef.dart';
import 'package:thesismob/frames/Materials/Plywood/PlywoodSolution.dart';
import 'package:thesismob/frames/Materials/Plywood/plywood.dart';
import 'package:thesismob/frames/Materials/Plywood/plywoodPages.dart';

import 'package:thesismob/frames/Materials/Roof/roof.dart';
import 'package:thesismob/frames/Materials/Roof/roofDef.dart';
import 'package:thesismob/frames/Materials/Roof/roofSolution.dart';
import 'package:thesismob/frames/Materials/Roof/roofPages.dart';

import 'package:thesismob/frames/Materials/Paint/paint.dart';
import 'package:thesismob/frames/Materials/Paint/paintPages.dart';
import 'package:thesismob/frames/Materials/Paint/paintDef.dart';
import 'package:thesismob/frames/Materials/Paint/paintSolution.dart';

import 'package:thesismob/frames/Materials/Bullb/bulb.dart';
import 'package:thesismob/frames/Materials/Bullb/bulbDOF.dart';
import 'package:thesismob/frames/Materials/Bullb/bulbSolution.dart';
import 'package:thesismob/frames/Materials/Bullb/bulbPages.dart';

import 'package:thesismob/frames/Materials/PVC/pvc.dart';
import 'package:thesismob/frames/Materials/PVC/pcvDef.dart';
import 'package:thesismob/frames/Materials/PVC/pvcSolution.dart';
import 'package:thesismob/frames/Materials/PVC/pvcPages.dart';

import 'package:thesismob/frames/Materials/insulation/insulation.dart';
import 'package:thesismob/frames/Materials/insulation/insulationPages.dart';
import 'package:thesismob/frames/Materials/insulation/insulationDef.dart';
import 'package:thesismob/frames/Materials/insulation/insulationSolution.dart';

import 'package:thesismob/frames/Materials/ConjunctionBox/cb.dart';
import 'package:thesismob/frames/Materials/ConjunctionBox/cbPages.dart';
import 'package:thesismob/frames/Materials/ConjunctionBox/cbDef.dart';
import 'package:thesismob/frames/Materials/ConjunctionBox/cbSol.dart';

import 'package:thesismob/frames/Materials/Switch/switch.dart';
import 'package:thesismob/frames/Materials/Switch/switchPages.dart';
import 'package:thesismob/frames/Materials/Switch/switchDef.dart';
import 'package:thesismob/frames/Materials/Switch/switchSol.dart';

import 'package:thesismob/frames/Materials/Sink/Sink.dart';
import 'package:thesismob/frames/Materials/Sink/SinkPages.dart';
import 'package:thesismob/frames/Materials/Sink/SinkDef.dart';
import 'package:thesismob/frames/Materials/Sink/SinkSol.dart';

import 'package:thesismob/frames/Materials/Toilet/Toiletpages.dart';
import 'package:thesismob/frames/Materials/Toilet/toilet.dart';
import 'package:thesismob/frames/Materials/Toilet/toiletdef.dart';
import 'package:thesismob/frames/Materials/Toilet/toiletsol.dart';

import 'package:thesismob/frames/Materials/Socket/socketPages.dart';
import 'package:thesismob/frames/Materials/Socket/socket.dart';
import 'package:thesismob/frames/Materials/Socket/socketDef.dart';
import 'package:thesismob/frames/Materials/Socket/socketSol.dart';

import 'package:thesismob/frames/Materials/Faucet/faucet.dart';
import 'package:thesismob/frames/Materials/Faucet/faucetDef.dart';
import 'package:thesismob/frames/Materials/Faucet/faucetSol.dart';
import 'package:thesismob/frames/Materials/Faucet/faucetPages.dart';

import 'package:thesismob/frames/Materials/Carpet/Carpetpages.dart';
import 'package:thesismob/frames/Materials/Carpet/Carpet.dart';

import 'package:thesismob/frames/Materials/Wallpaper/wallpaper.dart';
import 'package:thesismob/frames/Materials/Wallpaper/wallpaperpages.dart';
import 'package:thesismob/frames/Materials/Wallpaper/wallpaperDef.dart';
import 'package:thesismob/frames/Materials/Wallpaper/wallpaperSol.dart';

import 'package:thesismob/frames/Materials/ElectricalWires/wires.dart';
import 'package:thesismob/frames/Materials/ElectricalWires/wiresPages.dart';
import 'package:thesismob/frames/Materials/ElectricalWires/wiresSol.dart';
import 'package:thesismob/frames/Materials/ElectricalWires/wiresDef.dart';

import 'package:thesismob/frames/Materials/UtilityBox/box.dart';
import 'package:thesismob/frames/Materials/UtilityBox/boxPages.dart';
import 'package:thesismob/frames/Materials/UtilityBox/boxDef.dart';
import 'package:thesismob/frames/Materials/UtilityBox/boxSol.dart';

import 'package:thesismob/frames/Materials/shower/shower.dart';
import 'package:thesismob/frames/Materials/shower/showerDef.dart';
import 'package:thesismob/frames/Materials/shower/showerPages.dart';
import 'package:thesismob/frames/Materials/shower/showerSol.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SheetInfoProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: prefer_const_constructors
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // ignore: prefer_const_constructors
      home: mainpage(),
      routes: {
        // ignore: prefer_const_constructors
        '/mainpage': (context) => mainpage(),
        '/sheetform': (context) => SheetInfoInput(),
        '/history': (context) => HistoryScreen(),

        // ignore: prefer_const_constructors
        '/instructions': (context) => instructions(),
        '/summary': (context) => Summary(),

        '/arch': (context) => architectural(),
        '/archPages': (context) => archpages(),
        '/struc': (context) => structural(),
        '/strucPages': (context) => structuralpages(),
        '/plumb': (context) => plumbing(),
        '/plumbPages': (context) => plumPages(),
        '/elec': (context) => electrical(),
        '/elecPages': (context) => elecPages(),

        '/CHBpages': (context) => pages(),
        '/chb': (context) => CHB(),
        '/CHBDef': (context) => DoF(),
        '/CHBSol': (context) => Solutions(),

        '/solutiontiles': (context) => SolutionsTiles(),
        '/definitiontiles': (context) => DoFTiles(),
        '/tiles': (context) => tiles(),
        '/tilesPages': (context) => Tilepages(),

        '/plywood': (context) => wood(),
        '/plywoodPages': (context) => plywoodpages(),
        '/plywoodDef': (context) => plywoodDef(),
        '/plywoodSolution': (context) => plywoodSol(),

        '/roof': (context) => roof(),
        '/roofDef': (context) => roofDef(),
        '/roofSolution': (context) => roofSol(),
        '/roofPages': (context) => roofpages(),

        '/paint': (context) => paint(),
        '/paintDef': (context) => paintDef(),
        '/paintSolution': (context) => paintSol(),
        '/paintPages': (context) => paintpages(),

        '/bulb': (context) => bulb(),
        '/bulbDef': (context) => bulbDef(),
        '/bulbSol': (context) => bulbSol(),
        '/bulbPages': (context) => bulbpages(),

        '/pvc': (context) => pipe(),
        '/pvcDef': (context) => pipeDef(),
        '/pvcSolution': (context) => pipeSol(),
        '/pvcPages': (context) => pvcpages(),

        '/insulation': (context) => insulation(),
        '/insulationPages': (context) => insulationpages(),
        '/insulationDef': (context) => insulationDef(),
        '/insulationSolution': (context) => insulationSol(),

        '/cb': (context) => cBox(),
        '/cbPages': (context) => cBoxpages(),
        '/cbDef': (context) => cBoxDef(),
        '/cbSol': (context) => cBoxSol(),

        '/switch': (context) => MySwitch(),
        '/switchPages': (context) => switchPages(),
        '/switchDef': (context) => switchDef(),
        '/switchSol': (context) => switchSol(),

        '/sinkPages': (context) => sinkpages(),
        '/sink': (context) => sink(),
        '/sinkdef': (context) => sinkdef(),
        '/sinksol': (context) => sinksol(),

        '/toiletPages': (context) => toiletpages(),
        '/toilet': (context) => toilet(),
        '/toiletdef': (context) => toiletdef(),
        '/toiletsol': (context) => toiletsol(),

        '/socketPages': (context) => socketPages(),
        '/socket': (context) => MySocket(),
        '/socketdef': (context) => socketDef(),
        '/socketsol': (context) => socketSol(),

        '/faucetPages': (context) => faucetPages(),
        '/faucet': (context) => Myfaucet(),
        '/faucetdef': (context) => faucetDef(),
        '/faucetsol': (context) => faucetSol(),

        '/carpetPages': (context) => carpetPages(),
        '/carpet': (context) => carpet(),
        '/carpetDef': (context) => carpetDef(),
        '/carpetSol': (context) => carpetSol(),

        '/wallpaperPages': (context) => wallpaperPages(),
        '/wallpaper': (context) => wallpaper(),
        '/wallpaperDef': (context) => wallpaperDef(),
        '/wallpaperSol': (context) => wallpaperSol(),

        '/wiresPages': (context) => wiresPages(),
        '/wires': (context) => wires(),
        '/wiresDef': (context) => wiresDef(),
        '/wiresSol': (context) => wiresSol(),

        '/boxPages': (context) => boxPages(),
        '/box': (context) => box(),
        '/boxDef': (context) => boxDef(),
        '/boxSol': (context) => boxSol(),

        '/showerPages': (context) => showerPages(),
        '/shower': (context) => shower(),
        '/showerDef': (context) => showerdef(),
        '/showerSol': (context) => showersol(),
      },
    );
  }
}
