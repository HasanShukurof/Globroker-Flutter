import 'package:flutter/material.dart';

class QuestionsScreen extends StatelessWidget {
  const QuestionsScreen({super.key});

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
          "Tez-tez verilən suallar",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ExpansionTile(
              shape: const Border(),
              title: Text(
                'Avans-gömrük ödənişləri nədən formalaşır?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Şəxsin hökumət ödəniş portalının Dövlət Gömrük Komitəsi üzrə VÖEN-Avans bölməsindən və Banklardan ödəniş tapşırığına əsasən sair daxilolmalar üzrə dövlət büdcəsinə apardığı ödnişlərdən formalaşır. Qeyd: Banklardan ödəniş tapşırığı əsasında aparılan sair ödənişlərin anında balansda əks olunması üçün banklardan ödənişin hökumət ödəniş portalı üzərindən aparılmasının tələb olunması tövsiyyə olunur.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              shape: const Border(),
              title: Text(
                'Avans-gömrük ödənişləri üzrə köçürülmüş məbləği bütün gömrük idarələrində istifadə etmək mümkündürmü?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Avans-gömrük ödənişləri üzrə köçürülmüş məbləğ istənilən gömrük idarəsində malların gömrük rəsmiləşdirilməsi zamanı istifadə edilə bilər.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              shape: const Border(),
              title: Text(
                'Əlavə dəyər vergisi üzrə yaranmış borcun avans məbləğdən deyil, ƏDV depozit hesabından daxil olan vəsaitdən silinməsi üçün hansı addımlar atılmalıdır?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'ƏDV üzrə yaranmış borc ilkin olaraq elektron hesab səhifəsindəki artıq ödəmələr üzrə ƏDV məbləğindən, sonra ƏDV depozit hesabından və əgər ƏDV depozit hesabındakı məbləğ bəyannamə üzrə yaranmış borcu qarşılamırsa avans hesabdan silinir. Qeyd: ƏDV üzrə gömrük borcunun ancaq ƏDV depozit hesabından silinməsi üçün ƏDV depozit hesabda daima kifayət qədər vəsaitin olması tövsiyə edilir.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              shape: const Border(),
              title: Text(
                'Eyni zamanda bir neçə gömrük bəyannaməsi təqdim edilmişdirsə, ilkin olaraq şəxsə zəruri olan bəyannamənin rəsmiləşdirilməsi üçün hansı addımlar atılmalıdır?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Şəxsə zəruri olan gömrük bəyannaməsi gömrük orqanına göndərilərkən həmin bəyannamənin nömrəsi əsasında HÖP üzərindən gömrük bəyannaməsindəki bütün borc məbləğinin ödənilməsi təmin edilməklə.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              shape: const Border(),
              title: Text(
                'Şəxsin balansının artırılması məqsədilə köçürdüyü vəsait elektron hesab səhifəsində hansı müddətdə öz əksini tapır?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Şəxsin hökumət ödəniş portalının Dövlət Gömrük Komitəsi üzrə VÖEN-Avans və gömrük bəyannaməsinin nömrəsi bölməsindən, eyni zamanda bankların internet-bank platformalarında olan HÖP bölməsindən apardığı ödənişlər anında, bank köçürmələri və ƏDV depozit hesabından aparılan ödənişlər isə dövlət büdcəsinə daxil olduqdan sonra elektron hesab səhifəsində öz əksini tapır.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
