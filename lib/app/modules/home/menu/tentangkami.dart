import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../../componen/color.dart';
class ProfilePerusahaanPage extends StatefulWidget {
  const ProfilePerusahaanPage({super.key});

  @override
  State<ProfilePerusahaanPage> createState() => _ProfilePerusahaanPageState();
}

class _ProfilePerusahaanPageState extends State<ProfilePerusahaanPage> {

  int _currentIndex = 0;
  final List<String> imgList = [
    'assets/images/gambar1.jpg',
    'assets/images/gambar2.jpg',
    'assets/images/gambar3.jpg',
    'assets/images/gambar4.jpg',
    'assets/images/gambar5.jpg',
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Perusahaan'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Slider(context),
            SizedBox(height: 20,),
            Text(
              'Tentang Kami',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: MyColors.appPrimaryColor,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Berawal dari jual beli mobil Mercedes-Benz yang mengusung konsep RESTORASI sebelum kendaraan sampai di tangan Buyer’s, karena kondisi yang PERFECT adalah mandatory disetiap penjualan unit kami.\n\n'
                  'Terbesit dari bisikan para Buyer’s yang menginginkan kendaraan mereka selalu tampil prima baik dari segi mesin dan body cat kendaraan, maka berdirilah REAL AUTO BENZ WORKSHOP yang bertujuan untuk memberikan layanan lebih sempurna bagi pelanggan dan Smart Buyer’s.\n\n'
                  'Kami ada karena hobi, kami bisa karena dibidangnya, kami ahli karena pengalaman kami, Datang dan buktikan bagaimana tim kami mampu membuat Merceds-Benz Anda Like NEW! dengan tahapan-tahapan proses servis berkualitas PREMIUM!',
              style: TextStyle(fontSize: 16.0, height: 1.5),
            ),
            SizedBox(height: 24.0),
            Text(
              'Visi Misi Perusahaan',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: MyColors.appPrimaryColor,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Menjadi bengkel spesialis terbaik dikelasnya, terdepan dan terpercaya dengan mengusung konsep “Mercykanlah Mercymu” karena untuk PERFECT semua melalui tahapan yang dibuktikan dengan kualitas servis kelas PREMIUM.\n\n'
                  'Memberikan produk kualitas PREMIUM baik jasa maupun spare part\n'
                  'Memberikan kemudahan bagi para pelanggan untuk melakukan servis kendaraan dengan support teknologi\n'
                  'Memberikan inovasi di setiap servis yang kami sajikan bagi pelanggan\n'
                  'Memberikan tranparasi data servis kendaraan khususnya harga dan kualitas part\n'
                  'Selalu terdepan dengan dukungan peralatan yang modern dan canggih disetiap servis kendaraan yang kami lakukan',
              style: TextStyle(fontSize: 16.0, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
  Widget _Slider(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 3),
            autoPlayAnimationDuration: Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            pauseAutoPlayOnTouch: true,
            aspectRatio: 2.7,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: imgList.map((item) => Container(
            margin: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image:  AssetImage(item),
                fit: BoxFit.cover,
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 10),
        Container(
          width: 130,
          decoration: BoxDecoration(
            color: MyColors.slider,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: imgList.map((url) {
              int index = imgList.indexOf(url);
              return Container(
                width: 19.0,
                height: 5.0,
                margin: EdgeInsets.symmetric(vertical: 7.0, horizontal: 2.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  shape: BoxShape.rectangle,
                  color: _currentIndex == index ? MyColors.appPrimaryColor : MyColors.slider,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
