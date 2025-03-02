import 'package:flutter/material.dart';

class BeyannameXidmetiScreen extends StatelessWidget {
  const BeyannameXidmetiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Bəyannamə Xidməti",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Gömrük bəyannamələrinin tərtibi",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E), // Koyu mavi
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Gömrük rəsmiləşdirilməsi malların və nəqliyyat vasitələrinin müvafiq gömrük proseduru altında yerləşdirilməsi və bu prosedurun başa çatdırılması üzrə həyata keçirilən hərəkətlərdir. GloBroker bütün növ gömrük bəyannamələrini sizin əvəzinizdən tərtib edib təhvil verir. Gömrük bəyannamələri aşağıdakı gömrük prosedurları zamanı tərtib edilir:",
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "İDXAL ƏMƏLİYYATI:",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: [
                  _buildOperationItem("Son istifadə"),
                  _buildOperationItem("Müvəqqəti idxal"),
                  _buildOperationItem("Sərbəst dövriyyə üçün buraxılış"),
                  _buildOperationItem("Gömrük anbarı"),
                  _buildOperationItem("Daxildə emal"),
                  _buildOperationItem("Müvəqqəti saxlanc"),
                  _buildOperationItem("Sərbəst zona"),
                  _buildOperationItem("Qısa idxal"),
                  _buildOperationItem("Beynəlxalq transit"),
                  _buildOperationItem("Daxili tranzit"),
                  _buildOperationItem("Təkrar idxal"),
                ],
              ),
              const SizedBox(height: 25),
              const Text(
                "İXRAC ƏMƏLİYYATI:",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: [
                  _buildOperationItem("İxrac"),
                  _buildOperationItem("Təkrar ixrac"),
                  _buildOperationItem("Müvəqqəti ixrac"),
                  _buildOperationItem("Xaricdə emal"),
                ],
              ),
              const SizedBox(
                height: 70,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperationItem(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
    );
  }
}
