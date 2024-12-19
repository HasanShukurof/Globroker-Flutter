import 'package:flutter/material.dart';

class SertifikatIcazeScreen extends StatelessWidget {
  const SertifikatIcazeScreen({super.key});

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
          "Sertifikat və İcazələr",
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
                "Sertifikat və icazələrin alınması",
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
                  "Ölkəyə xüsusi kateqoriyalı məhsulları idxal və ya ixrac etmək üçün icazə və sertifikatların alınması vacibdir. Əks halda yüklərin gömrük sərhədlərindən buraxılması mümkün deyil. GloBroker xərc və zamanınıza qənaət etməyiniz üçün bütün növ xüsusi icazə və sertifikatları sizin əvəzinizdən əldə edib sizə təqdim edir.",
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "Əsasən tələb olunan sertifikatlar, icazələr və onları təqdim edən orqanlar:",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 20),
              _buildCertificateItem(
                "Qida Fitosanitariya Baytarlıq Sertifikatı",
                "Azərbaycan Respublikasının Qida Təhlükəsizliyi Agentliyi",
              ),
              _buildCertificateItem(
                "Gigiyenik Sertifikat",
                "Respublika Sanitar-Karantin Mərkəzi",
              ),
              _buildCertificateItem(
                "Tibbi Məhsulların və Avadanlıqların idxal icazəsi",
                "Səhiyyə Analitik Ekspertiza Mərkəzi",
              ),
              _buildCertificateItem(
                "Mənşə sertifikatı",
                "Azərbaycan Respublikası İqtisadiyyat Nazirliyi",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificateItem(String title, String organization) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            organization,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
