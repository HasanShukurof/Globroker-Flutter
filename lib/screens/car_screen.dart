import 'package:flutter/material.dart';
import 'package:globroker/screens/key_input_service.dart';
import 'package:intl/intl.dart';

class CarScreen extends StatefulWidget {
  const CarScreen({super.key});

  @override
  State<CarScreen> createState() => _CarScreenState();
}

class _CarScreenState extends State<CarScreen>
    with SingleTickerProviderStateMixin {
  final matorController = TextEditingController();
  final qiymetController = TextEditingController();
  final dateController = TextEditingController();

  int? mator = 0;
  double? qiymet = 0;
  double? qiymetAzn = 0;
  int yigim = 0;
  int vesiqePulu = 30;
  int vesiqePuluQoshqu = 25;
  double idxalRusumu = 0;
  double aksiz = 0;
  double xidmetHaqqi = 35.40;
  double edv = 0;
  int kohneUygunluq = 60;
  int yeniUygunluq = 60;
  int utilizasiya = 0;
  double? result = 0.00;
  String formatedResultText = "";

  int myValue = 0;
  Duration ferq = const Duration();
  late int gunFerqi;
  late int ilFerqi;

  bool isDetailsVisible = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDetails() {
    setState(() {
      gunFerqi = ferq.inDays;
      isDetailsVisible = !isDetailsVisible;
      if (isDetailsVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          "Minik Avtomobili",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Tarix Bölməsi
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: "İstehsal Tarixi",
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(30),
                    ),
                  ),
                ),
                readOnly: true,
                onTap: () {
                  datePicker();
                },
              ),
              const SizedBox(height: 20),

              // Mator Bölməsi

              TextField(
                inputFormatters: [NumericInputFormatter()],
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                controller: matorController,
                decoration: const InputDecoration(
                  labelText: "Mühərrik (sm3)",
                  prefixIcon: Icon(Icons.car_repair_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              //  Dəyər Bölməsi
              TextField(
                inputFormatters: [NumericInputFormatter()],
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                controller: qiymetController,
                decoration: const InputDecoration(
                  labelText: "Dəyər",
                  prefixIcon: Icon(Icons.attach_money_sharp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Mühərrik Növü"),

              // Radio Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Radio(
                        value: 1,
                        groupValue: myValue,
                        onChanged: (value) {
                          setState(
                            () {
                              myValue = value!;
                            },
                          );
                        },
                      ),
                      const Text("Benzin"),
                    ],
                  ),
                  Column(
                    children: [
                      Radio(
                        value: 2,
                        groupValue: myValue,
                        onChanged: (value) {
                          setState(
                            () {
                              myValue = value!;
                            },
                          );
                        },
                      ),
                      const Text("Dizel"),
                    ],
                  ),
                  Column(
                    children: [
                      Radio(
                        value: 3,
                        groupValue: myValue,
                        onChanged: (value) {
                          setState(
                            () {
                              myValue = value!;
                            },
                          );
                        },
                      ),
                      const Text("Hybrid"),
                    ],
                  ),
                  Column(
                    children: [
                      Radio(
                        value: 4,
                        groupValue: myValue,
                        onChanged: (value) {
                          setState(
                            () {
                              myValue = value!;
                            },
                          );
                        },
                      ),
                      const Text("Elektrik"),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              //  HESABLA BUTTONU
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.only(left: 80, right: 80),
                ),
                onPressed: () {
                  setState(
                    () {
                      if (dateController.text.isEmpty &&
                          matorController.text.isEmpty &&
                          qiymetController.text.isEmpty &&
                          myValue == 0) {
                        formatedResultText = "Boş Xanaları Doldurun";
                        isDetailsVisible = false;
                        _animationController.reverse();
                      } else {
                        if (myValue == 0) {
                          formatedResultText = "Boş Xanaları Doldurun";
                          isDetailsVisible = false;
                          _animationController.reverse();
                        } else if (myValue == 1) {
                          if (dateController.text.isEmpty) {
                            formatedResultText = "Tarix qeyd edin";
                            isDetailsVisible = false;
                            _animationController.reverse();
                          } else if (matorController.text.isEmpty) {
                            formatedResultText = "Mühərrik həcmini qeyd edin";
                            isDetailsVisible = false;
                            _animationController.reverse();
                          } else if (qiymetController.text.isEmpty) {
                            formatedResultText = "Qiymət qeyd edin";
                            isDetailsVisible = false;
                            _animationController.reverse();
                          } else {
                            benzin();
                          }
                        } else if (myValue == 2) {
                          if (dateController.text.isEmpty) {
                            formatedResultText = "Tarix qeyd edin";
                            isDetailsVisible = false;
                            _animationController.reverse();
                          } else if (matorController.text.isEmpty) {
                            formatedResultText = "Mühərrik həcmini qeyd edin";
                            isDetailsVisible = false;
                            _animationController.reverse();
                          } else if (qiymetController.text.isEmpty) {
                            formatedResultText = "Qiymət qeyd edin";
                            isDetailsVisible = false;
                            _animationController.reverse();
                          } else {
                            dizel();
                          }
                        } else if (myValue == 3) {
                          if (dateController.text.isEmpty) {
                            formatedResultText = "Tarix qeyd edin";
                            isDetailsVisible = false;
                            _animationController.reverse();
                          } else if (matorController.text.isEmpty) {
                            formatedResultText = "Mühərrik həcmini qeyd edin";
                            isDetailsVisible = false;
                            _animationController.reverse();
                          } else if (qiymetController.text.isEmpty) {
                            formatedResultText = "Qiymət qeyd edin";
                            isDetailsVisible = false;
                            _animationController.reverse();
                          } else {
                            hybrid();
                          }
                        } else if (myValue == 4) {
                          if (dateController.text.isEmpty) {
                            formatedResultText = "Tarix qeyd edin";
                            isDetailsVisible = false;
                            _animationController.reverse();
                          } else if (matorController.text.isEmpty) {
                            formatedResultText =
                                "Mühərrik həcmini  0  qeyd edin";
                            isDetailsVisible = false;
                            _animationController.reverse();
                          } else if (qiymetController.text.isEmpty) {
                            formatedResultText = "Qiymət qeyd edin";
                            isDetailsVisible = false;
                            _animationController.reverse();
                          } else {
                            elektrik();
                          }
                        }
                      }
                    },
                  );
                  FocusScope.of(context).unfocus();
                },
                child: const Text(
                  "Hesabla",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              //  Kassa Texti
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Kassa: $formatedResultText",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  // Flexible(
                  //   child: IconButton(
                  //     icon: Icon(isDetailsVisible
                  //         ? Icons.arrow_drop_up
                  //         : Icons.arrow_drop_down),
                  //     onPressed: _toggleDetails,
                  //   ),
                  // ),
                ],
              ),

              const SizedBox(height: 20),
              // Detaylar
              SizeTransition(
                sizeFactor: _animation,
                child: isDetailsVisible
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Gömrük Yığımı: $yigim AZN",
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text("Vəsiqə Pulu: $vesiqePulu AZN",
                                style: const TextStyle(fontSize: 16)),
                            Text(
                                "İdxal Rüsumu: ${idxalRusumu.toStringAsFixed(2)} AZN",
                                style: const TextStyle(fontSize: 16)),
                            Text(
                                "Aksiz Vergisi: ${aksiz.toStringAsFixed(2)} AZN",
                                style: const TextStyle(fontSize: 16)),
                            Text("ƏDV: ${edv.toStringAsFixed(2)} AZN",
                                style: const TextStyle(fontSize: 16)),
                            Text(
                                "Xidmət Haqqı: ${xidmetHaqqi.toStringAsFixed(2)} AZN",
                                style: const TextStyle(fontSize: 16)),
                            Text(
                                "Uyğunluq: ${gunFerqi >= 365 ? kohneUygunluq : yeniUygunluq} AZN",
                                style: const TextStyle(fontSize: 16)),
                            Text("Utilizasiya: $utilizasiya AZN",
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(
                              height: 10,
                            ),
                            const Divider(
                              height: 2,
                              color: Colors.black,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text("Toplam: ${result?.toStringAsFixed(2)} AZN",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void benzin() {
    mator = int.parse(matorController.text);
    qiymet = double.parse(qiymetController.text);
    gunFerqi = ferq.inDays;

    if (qiymet != null) {
      qiymetAzn = qiymet! * 1.70;
    }

    // --------- Gomruk Yigimi ----------

    if (qiymetAzn! <= 1000) {
      yigim = 15;
    } else if (qiymetAzn! <= 10000) {
      yigim = 60;
    } else if (qiymetAzn! <= 50000) {
      yigim = 120;
    } else if (qiymetAzn! <= 100000) {
      yigim = 200;
    } else if (qiymetAzn! <= 500000) {
      yigim = 300;
    } else if (qiymetAzn! <= 1000000) {
      yigim = 600;
    } else {
      yigim = 1000;
    }

    // ------- Idxal rusumu -------
    if (mator != null) {
      if (mator! <= 1500) {
        if (gunFerqi <= 365) {
          idxalRusumu = mator! * 0.68;
        } else {
          idxalRusumu = mator! * 1.19;
        }
      } else {
        if (gunFerqi <= 365) {
          idxalRusumu = mator! * 1.19;
        } else {
          idxalRusumu = mator! * 2.04;
        }
      }
    }

    // ------- Aksiz vergisi -------

    if (mator != null) {
      if (mator! <= 2000) {
        if (gunFerqi >= 2555) {
          aksiz = mator! * 0.30 * 1.2;
        } else {
          aksiz = mator! * 0.30;
        }
      } else if (mator! <= 3000) {
        if (gunFerqi >= 2555) {
          aksiz = ((mator! - 2000.00) * 5.00 + 600.00) * 1.2;
        } else {
          aksiz = (mator! - 2000.00) * 5.00 + 600.00;
        }
      } else if (mator! <= 4000) {
        if (gunFerqi >= 2555) {
          aksiz = ((mator! - 3000.00) * 15.00 + 5600.00) * 1.2;
        } else if (gunFerqi >= 1095) {
          aksiz = (mator! - 3000.00) * 15.00 + 5600.00;
        } else {
          aksiz = (mator! - 3000.00) * 13.00 + 5600.00;
        }
      } else if (mator! <= 5000) {
        if (gunFerqi >= 2555) {
          aksiz = ((mator! - 4000.00) * 40.00 + 20600.00) * 1.2;
        } else if (gunFerqi >= 1095) {
          aksiz = (mator! - 4000.00) * 40.00 + 20600.00;
        } else {
          aksiz = (mator! - 4000.00) * 35.00 + 18600.00;
        }
      } else if (mator! > 5000) {
        if (gunFerqi >= 2555) {
          aksiz = ((mator! - 5000.00) * 80.00 + 60600.00) * 1.2;
        } else if (gunFerqi >= 1095) {
          aksiz = (mator! - 5000.00) * 80.00 + 60600.00;
        } else {
          aksiz = (mator! - 5000.00) * 70.00 + 53600.00;
        }
      }
    }

    // Utilizasiya
    if (ilFerqi >= 4 && ilFerqi < 7) {
      utilizasiya = 400;
    } else if (ilFerqi >= 7) {
      utilizasiya = 700;
    } else {
      utilizasiya = 0;
    }

    edv = ((qiymetAzn! + idxalRusumu + aksiz + vesiqePulu) * 18) / 100;

    if (gunFerqi >= 365) {
      result = yigim +
          kohneUygunluq +
          vesiqePulu +
          idxalRusumu +
          aksiz +
          edv +
          xidmetHaqqi +
          utilizasiya;
    } else {
      result = yigim +
          yeniUygunluq +
          vesiqePulu +
          idxalRusumu +
          aksiz +
          edv +
          xidmetHaqqi +
          utilizasiya;
    }
    formatedResultText = "${result!.toStringAsFixed(2)} AZN";
    if (result != null) {
      _toggleDetails();
    }
  }

  void dizel() {
    mator = int.parse(matorController.text);
    qiymet = double.parse(qiymetController.text);
    gunFerqi = ferq.inDays;

    if (qiymet != null) {
      qiymetAzn = qiymet! * 1.70;
    }

    // --------- Gomruk Yigimi ----------

    if (qiymetAzn! <= 1000) {
      yigim = 15;
    } else if (qiymetAzn! <= 10000) {
      yigim = 60;
    } else if (qiymetAzn! <= 50000) {
      yigim = 120;
    } else if (qiymetAzn! <= 100000) {
      yigim = 200;
    } else if (qiymetAzn! <= 500000) {
      yigim = 300;
    } else if (qiymetAzn! <= 1000000) {
      yigim = 600;
    } else {
      yigim = 1000;
    }

    // ------- Idxal rusumu -------
    if (mator != null) {
      if (mator! <= 1500) {
        if (gunFerqi <= 365) {
          idxalRusumu = mator! * 0.68;
        } else {
          idxalRusumu = mator! * 1.19;
        }
      } else {
        if (gunFerqi <= 365) {
          idxalRusumu = mator! * 1.19;
        } else {
          idxalRusumu = mator! * 2.04;
        }
      }
    }

    // ------- Aksiz vergisi -------

    if (mator != null) {
      if (mator! <= 2000) {
        if (gunFerqi >= 2555) {
          aksiz = mator! * 0.30 * 1.5;
        } else {
          aksiz = mator! * 0.30;
        }
      } else if (mator! <= 3000) {
        if (gunFerqi >= 2555) {
          aksiz = ((mator! - 2000.00) * 5.00 + 600.00) * 1.5;
        } else {
          aksiz = (mator! - 2000.00) * 5.00 + 600.00;
        }
      } else if (mator! <= 4000) {
        if (gunFerqi >= 2555) {
          aksiz = ((mator! - 3000.00) * 15.00 + 5600.00) * 1.5;
        } else if (gunFerqi >= 1095) {
          aksiz = (mator! - 3000.00) * 15.00 + 5600.00;
        } else {
          aksiz = (mator! - 3000.00) * 13.00 + 5600.00;
        }
      } else if (mator! <= 5000) {
        if (gunFerqi >= 2555) {
          aksiz = ((mator! - 4000.00) * 40.00 + 20600.00) * 1.5;
        } else if (gunFerqi >= 1095) {
          aksiz = (mator! - 4000.00) * 40.00 + 20600.00;
        } else {
          aksiz = (mator! - 4000.00) * 35.00 + 18600.00;
        }
      } else if (mator! > 5000) {
        if (gunFerqi >= 2555) {
          aksiz = ((mator! - 5000.00) * 80.00 + 60600.00) * 1.5;
        } else if (gunFerqi >= 1095) {
          aksiz = (mator! - 5000.00) * 80.00 + 60600.00;
        } else {
          aksiz = (mator! - 5000.00) * 70.00 + 53600.00;
        }
      }
    }

    // Utilizasiya
    if (ilFerqi >= 4 && ilFerqi < 7) {
      utilizasiya = 400;
    } else if (ilFerqi >= 7) {
      utilizasiya = 700;
    } else {
      utilizasiya = 0;
    }

    edv = ((qiymetAzn! + idxalRusumu + aksiz + vesiqePulu) * 18) / 100;

    if (gunFerqi >= 365) {
      result = yigim +
          kohneUygunluq +
          vesiqePulu +
          idxalRusumu +
          aksiz +
          edv +
          xidmetHaqqi +
          utilizasiya;
    } else {
      result = yigim +
          yeniUygunluq +
          vesiqePulu +
          idxalRusumu +
          aksiz +
          edv +
          xidmetHaqqi +
          utilizasiya;
    }

    formatedResultText = "${result!.toStringAsFixed(2)} AZN";
    if (result != null) {
      _toggleDetails();
    }
  }

  void hybrid() {
    mator = int.parse(matorController.text);
    qiymet = double.parse(qiymetController.text);
    gunFerqi = ferq.inDays;

    if (qiymet != null) {
      qiymetAzn = qiymet! * 1.70;
    }

    // --------- Gomruk Yigimi ----------

    if (qiymetAzn! <= 1000) {
      yigim = 15;
    } else if (qiymetAzn! <= 10000) {
      yigim = 60;
    } else if (qiymetAzn! <= 50000) {
      yigim = 120;
    } else if (qiymetAzn! <= 100000) {
      yigim = 200;
    } else if (qiymetAzn! <= 500000) {
      yigim = 300;
    } else if (qiymetAzn! <= 1000000) {
      yigim = 600;
    } else {
      yigim = 1000;
    }

    // ------- Idxal rusumu -------
    if (mator != null) {
      if (mator! <= 1500) {
        if (gunFerqi <= 365) {
          idxalRusumu = mator! * 0.68;
        } else {
          idxalRusumu = mator! * 1.19;
        }
      } else {
        if (gunFerqi <= 365) {
          idxalRusumu = mator! * 1.19;
        } else {
          idxalRusumu = mator! * 2.04;
        }
      }
    }

    // ------- Aksiz vergisi -------

    if (mator != null) {
      if (mator! <= 2000) {
        if (gunFerqi >= 2555) {
          aksiz = mator! * 0.30 * 1.2;
        } else {
          aksiz = mator! * 0.30;
        }
      } else if (mator! <= 3000) {
        if (gunFerqi >= 2555) {
          aksiz = ((mator! - 2000.00) * 5.00 + 600.00) * 1.2;
        } else {
          aksiz = (mator! - 2000.00) * 5.00 + 600.00;
        }
      } else if (mator! <= 4000) {
        if (gunFerqi >= 2555) {
          aksiz = ((mator! - 3000.00) * 15.00 + 5600.00) * 1.2;
        } else if (gunFerqi >= 1095) {
          aksiz = (mator! - 3000.00) * 15.00 + 5600.00;
        } else {
          aksiz = (mator! - 3000.00) * 13.00 + 5600.00;
        }
      } else if (mator! <= 5000) {
        if (gunFerqi >= 2555) {
          aksiz = ((mator! - 4000.00) * 40.00 + 20600.00) * 1.2;
        } else if (gunFerqi >= 1095) {
          aksiz = (mator! - 4000.00) * 40.00 + 20600.00;
        } else {
          aksiz = (mator! - 4000.00) * 35.00 + 18600.00;
        }
      } else if (mator! > 5000) {
        if (gunFerqi >= 2555) {
          aksiz = ((mator! - 5000.00) * 80.00 + 60600.00) * 1.2;
        } else if (gunFerqi >= 1095) {
          aksiz = (mator! - 5000.00) * 80.00 + 60600.00;
        } else {
          aksiz = (mator! - 5000.00) * 70.00 + 53600.00;
        }
      }
    }

    // Utilizasiya
    if (ilFerqi >= 4 && ilFerqi < 7) {
      utilizasiya = 400;
    } else if (ilFerqi >= 7) {
      utilizasiya = 700;
    } else {
      utilizasiya = 0;
    }

    // EDV

    if (mator! <= 2500 && gunFerqi <= 1095) {
      edv = 0.00;
    } else {
      edv = ((qiymetAzn! + idxalRusumu + aksiz + vesiqePulu) * 18) / 100;
    }

    if (gunFerqi >= 365) {
      result = yigim +
          kohneUygunluq +
          vesiqePulu +
          idxalRusumu +
          aksiz +
          edv +
          xidmetHaqqi +
          utilizasiya;
    } else {
      result = yigim +
          yeniUygunluq +
          vesiqePulu +
          idxalRusumu +
          aksiz +
          edv +
          xidmetHaqqi +
          utilizasiya;
    }

    formatedResultText = "${result!.toStringAsFixed(2)} AZN";
    if (result != null) {
      _toggleDetails();
    }
  }

  void elektrik() {
    mator = int.parse(matorController.text);
    qiymet = double.parse(qiymetController.text);
    gunFerqi = ferq.inDays;

    if (qiymet != null) {
      qiymetAzn = qiymet! * 1.70;
    }

    // --------- Gomruk Yigimi ----------

    if (qiymetAzn! <= 1000) {
      yigim = 15;
    } else if (qiymetAzn! <= 10000) {
      yigim = 60;
    } else if (qiymetAzn! <= 50000) {
      yigim = 120;
    } else if (qiymetAzn! <= 100000) {
      yigim = 200;
    } else if (qiymetAzn! <= 500000) {
      yigim = 300;
    } else if (qiymetAzn! <= 1000000) {
      yigim = 600;
    } else {
      yigim = 1000;
    }

    // ------- Idxal rusumu -------

    if (gunFerqi >= 1095) {
      idxalRusumu = qiymetAzn! * 15 / 100;
    } else {
      idxalRusumu = 0.00;
    }

    // Utilizasiya
    if (ilFerqi >= 4 && ilFerqi < 7) {
      utilizasiya = 400;
    } else if (ilFerqi >= 7) {
      utilizasiya = 700;
    } else {
      utilizasiya = 0;
    }

    result = yigim + vesiqePulu + idxalRusumu + xidmetHaqqi + utilizasiya;

    formatedResultText = "${result!.toStringAsFixed(2)} AZN";
    if (result != null) {
      _toggleDetails();
    }
  }

  Future<void> datePicker() async {
    DateTime? picked = await showDatePicker(
      context: context,
      fieldHintText: 'gün-ay-il',
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    final day1 = DateTime.now();
    final day2 = picked;
    ferq = day1.difference(day2!);
    ilFerqi = day1.year - day2.year;

    if (picked != null) {
      dateController.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }
}
