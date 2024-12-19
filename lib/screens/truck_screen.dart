import 'package:flutter/material.dart';
import 'package:globroker/screens/key_input_service.dart';

class TruckScreen extends StatefulWidget {
  const TruckScreen({super.key});

  @override
  State<TruckScreen> createState() => _TruckScreenState();
}

class _TruckScreenState extends State<TruckScreen> {
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
  double? result = 0.00;
  String formatedResultText = "";

  int myValue = 0;
  Duration ferq = const Duration();
  late int gunFerqi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          "Yük Avtomobili",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 26,
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
              const Text("Nəqliyyat Vasitəsinin Növü"),

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
                      const Text("Dartıcı"),
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
                      const Text("Qoşqu"),
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
                      const Text("Yük"),
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
                  setState(() {
                    if (dateController.text.isEmpty &&
                        matorController.text.isEmpty &&
                        qiymetController.text.isEmpty) {
                      formatedResultText = "Boş Xanaları Doldurun";
                    } else {
                      if (myValue == 0) {
                        formatedResultText = "Boş Xanaları Doldurun";
                      } else if (myValue == 1) {
                        if (dateController.text.isEmpty) {
                          formatedResultText = "Tarix qeyd edin";
                        } else if (matorController.text.isEmpty) {
                          formatedResultText = "Mühərrik həcmini qeyd edin";
                        } else if (qiymetController.text.isEmpty) {
                          formatedResultText = "Qiymət qeyd edin";
                        } else {
                          dartici();
                        }
                      } else if (myValue == 2) {
                        if (dateController.text.isEmpty) {
                          formatedResultText = "Tarix qeyd edin";
                        } else if (matorController.text.isEmpty) {
                          formatedResultText = "Mühərrik həcmini  0  qeyd edin";
                        } else if (qiymetController.text.isEmpty) {
                          formatedResultText = "Qiymət qeyd edin";
                        } else {
                          qoshqu();
                        }
                      } else if (myValue == 3) {
                        if (dateController.text.isEmpty) {
                          formatedResultText = "Tarix qeyd edin";
                        } else if (matorController.text.isEmpty) {
                          formatedResultText = "Mühərrik həcmini qeyd edin";
                        } else if (qiymetController.text.isEmpty) {
                          formatedResultText = "Qiymət qeyd edin";
                        } else {
                          yuk();
                        }
                      }
                    }
                  });
                },
                child: const Text(
                  "Hesabla",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              //  Kassa Texti
              Text(
                "Kassa: $formatedResultText",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void dartici() {
    setState(() {
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

      //   EDV

      edv = ((qiymetAzn! + vesiqePulu) * 18) / 100;

      if (gunFerqi >= 365) {
        result = yigim + kohneUygunluq + vesiqePulu + edv + xidmetHaqqi;
      } else {
        result = yigim + yeniUygunluq + vesiqePulu + edv + xidmetHaqqi;
      }

      formatedResultText = "${result!.toStringAsFixed(2)} AZN";
    });
  }

  void qoshqu() {
    setState(() {
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
      if (qiymetAzn != null) {
        idxalRusumu = qiymetAzn! * 5 / 100;
      }

      //   EDV

      edv = ((qiymetAzn! + idxalRusumu + vesiqePuluQoshqu) * 18) / 100;

      result = yigim + vesiqePuluQoshqu + idxalRusumu + edv + xidmetHaqqi;

      formatedResultText = "${result!.toStringAsFixed(2)} AZN";
    });
  }

  void yuk() {
    setState(
      () {
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
          if (gunFerqi >= 365) {
            idxalRusumu = mator! * 0.7 * 1.7;
          } else {
            idxalRusumu = qiymetAzn! * 5 / 100;
          }
        }

        //   EDV
        edv = ((qiymetAzn! + idxalRusumu + vesiqePulu) * 18) / 100;

        //  Yekun Hesablama

        if (gunFerqi >= 365) {
          result = yigim +
              kohneUygunluq +
              vesiqePulu +
              idxalRusumu +
              edv +
              xidmetHaqqi;
        } else {
          result = yigim +
              yeniUygunluq +
              vesiqePulu +
              idxalRusumu +
              edv +
              xidmetHaqqi;
        }
        formatedResultText = "${result!.toStringAsFixed(2)} AZN";
      },
    );
  }

  Future<void> datePicker() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    final day1 = DateTime.now();
    final day2 = picked;
    ferq = day1.difference(day2!);

    if (picked != null) {
      dateController.text = picked.toString().split(" ")[0];
    }
  }
}