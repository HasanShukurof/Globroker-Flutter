import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser!;

  bool _isLoading = false;
  File? _selectedImage;
  String? _currentPhotoURL;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _nameController.text = userData['displayName'] ?? '';
        _currentPhotoURL = userData['photoURL'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İstifadəçi məlumatları yüklənərkən xəta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? photoURL = _currentPhotoURL;

      // Eğer yeni resim seçildiyse, yükle
      if (_selectedImage != null) {
        try {
          // Dosya uzantısını al
          final fileExtension = path.extension(_selectedImage!.path);
          final fileName = 'profile$fileExtension';

          print('Dosya yükleniyor: user_images/${_currentUser.uid}/$fileName');

          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child(_currentUser.uid)
              .child(fileName);

          // Yükleme işlemini başlat
          final uploadTask = storageRef.putFile(_selectedImage!);

          // Yükleme durumunu izle
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            print('Yükleme durumu: ${snapshot.state}');
            print(
                'Yüklenen: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
          });

          // Yükleme tamamlandığında
          await uploadTask.whenComplete(() => print('Resim yüklendi'));

          // Yükleme başarılı olduysa URL'i al
          photoURL = await storageRef.getDownloadURL();

          print('Resim URL: $photoURL');
        } catch (e) {
          print('Resim yükleme hatası detayları:');
          print('Hata türü: ${e.runtimeType}');
          print('Hata mesajı: $e');

          if (e is FirebaseException) {
            print('Firebase hata kodu: ${e.code}');
            print('Firebase hata mesajı: ${e.message}');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profil şəkli yüklənərkən xəta: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Firestore'da kullanıcı bilgilerini güncelle
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(_currentUser.uid)
          .update({
        'displayName': _nameController.text.trim(),
        'photoURL': photoURL,
      });

      // Firebase Auth'da kullanıcı bilgilerini güncelle
      await _currentUser.updateDisplayName(_nameController.text.trim());
      if (photoURL != null) {
        await _currentUser.updatePhotoURL(photoURL);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil uğurla yeniləndi'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Profil güncelleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil yenilənərkən xəta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şəkil seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Qalereyadan seçin'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera ilə çəkin'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ləğv et'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili düzənlə'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!) as ImageProvider
                                : (_currentPhotoURL != null
                                    ? NetworkImage(_currentPhotoURL!)
                                    : null),
                            child: (_selectedImage == null &&
                                    _currentPhotoURL == null)
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Zəhmət olmasa adınızı daxil edin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Yadda saxla',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
