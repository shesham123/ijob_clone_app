import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ijob_clone_app/Services/global_methods.dart';
import 'package:ijob_clone_app/Services/global_variables.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';


class SignUp extends StatefulWidget {

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> with TickerProviderStateMixin{

  late Animation<double>?_animation;
  late  AnimationController _animationController;

  final TextEditingController _fullNameControlller = TextEditingController(text: '');
  final TextEditingController _emailTextController= TextEditingController(text: '');
  final TextEditingController _passTextController= TextEditingController(text: '');
  final TextEditingController _phoneNumberController= TextEditingController(text: '');
  final TextEditingController _locationController= TextEditingController(text: '');



  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();
  final FocusNode _phoneNumbersFocusNode = FocusNode();
  final FocusNode _positionCPFocusNode = FocusNode();



  final _signUpFormKey = GlobalKey<FormState>();
  bool _obscureText = true;
  File? imageFile;
  final FirebaseAuth _auth =FirebaseAuth.instance;
  bool _isLoading = false;
  String? imageUrl;


  @override
  void dispose() {
    _animationController.dispose();
    _fullNameControlller.dispose();
    _emailTextController.dispose();
    _passTextController.dispose();
    _phoneNumberController.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    _positionCPFocusNode.dispose();
    _phoneNumbersFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _animationController =AnimationController(vsync: this ,duration: const Duration(seconds: 20));
    _animation =CurvedAnimation(parent: _animationController, curve: Curves.linear)
      ..addListener(() {
        setState(() { });
      })..addStatusListener((animationSatus) {
        if (animationSatus==AnimationStatus.completed){
          _animationController.reset();
          _animationController.forward();
        }
      });
    _animationController.forward();
    super.initState();
  }
  void _showImageDialog()
  {
    showDialog(
        context: context,
        builder: (context)
        {
          return AlertDialog(
            title: const Text('Please choose an option'),
            content:  Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    _getFormCamera();
                  },
                  child: Row(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.camera,
                            color: Colors.purple,
                          ),
                        ),
                        Text(
                          'Camera',
                          style: TextStyle(color: Colors.purple),
                        )
                      ]
                  ),
                ),
                InkWell(
                  onTap: () {
                    _getFormGellary();
                  },
                  child: Row(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.image,
                            color: Colors.purple,
                          ),
                        ),
                        Text(
                          'Gellery',
                          style: TextStyle(color: Colors.purple),
                        )
                      ]
                  ),
                ),
              ],
            ),
          );

        }
    );
  }

  void _getFormCamera() async
  {
    XFile? PickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    _cropImage(PickedFile!.path);
    Navigator.pop(context);
  }

  void _getFormGellary() async
  {
    XFile? PickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    _cropImage(PickedFile!.path);
    Navigator.pop(context);
  }

  void _cropImage(FieldPath) async
  {
    CroppedFile? croppedImage =await ImageCropper().cropImage(
        sourcePath:FieldPath, maxHeight: 1080, maxWidth: 1080
    );

    if(croppedImage != null)
    {
      setState(() {
        imageFile = File(croppedImage.path);
      });
    }
  }
  void _submitFormOnSignup() async
  {
    final isValid = _signUpFormKey.currentState!.validate();
    if (isValid)
    {
      if(imageFile == null)
      {
        GlobalMethod.showErrorDialog(
          error: 'Pleasse pick an image',
          ctx: context,
        );
        return;
      }
      setState(() {
        _isLoading =true;
      });
      try
      {
        await _auth.createUserWithEmailAndPassword(
          email: _emailTextController.text.trim().toLowerCase(),
          password: _passTextController.text.trim(),
        );
        final User? user = _auth.currentUser;
        final _uid = user!.uid;
        final ref =FirebaseStorage.instance.ref().child('userImages').child(_uid +'.jpg');
        await ref.putFile(imageFile!);
        imageUrl =await ref .getDownloadURL();
        FirebaseFirestore.instance.collection('users').doc(_uid).set({
          'id': _uid,
          'name': _fullNameControlller.text,
          'email': _emailTextController.text,
          'userImage': imageUrl,
          'phoneNumber': _phoneNumberController.text,
          'location': _locationController.text,
          'createAt': Timestamp.now(),
        });
        Navigator.canPop(context)? Navigator.pop(context): null;
      }catch (error)
      {
        setState(() {
          _isLoading =false;
        });
        GlobalMethod.showErrorDialog(error: error.toString(), ctx: context);
      }
    }
    setState(() {
      _isLoading =false;
    });
  }


  @override
  Widget build (BuildContext context){
    Size size =MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: signUpUrlImage,
            placeholder: (context, url) => Image.asset(
              'assets/images/wallpaper.jpg',
              fit: BoxFit.fill,
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            alignment: FractionalOffset(_animation!.value,0),
          ),
          Container(
            color: Colors.black54,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16 ,vertical: 80),
              child: ListView(
                children: [
                  Form(
                    key:  _signUpFormKey,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: ()
                          {
                            _showImageDialog();
                            //create show ImageDialog
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              width: size.width*0.24,
                              height: size.width*0.24,
                              decoration: BoxDecoration(
                                border: Border.all(width: 1, color: Colors.cyanAccent,),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: imageFile == null
                                    ? const Icon(Icons.camera_enhance_sharp, color: Colors.cyan, size: 30,)
                                    : Image.file(imageFile!, fit: BoxFit.fill,),
                              ),

                            ),
                          ),
                        ),
                        const SizedBox(height: 20,),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () =>  FocusScope.of(context).requestFocus(_emailFocusNode),
                          keyboardType: TextInputType.name,
                          controller: _fullNameControlller ,
                          // obscureText: false,
                          validator: (value)
                          {
                            if(value!.isEmpty)
                            {
                              return 'This Field is missing';
                            }
                            else
                            {
                              return null;
                            }
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText:  "Full name / Company name",
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            errorBorder:  UnderlineInputBorder(
                              borderSide: BorderSide(color:  Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20,),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () =>  FocusScope.of(context).requestFocus(_passFocusNode),
                          keyboardType: TextInputType.emailAddress,
                          controller:  _emailTextController,
                          // obscureText: false,
                          validator: (value)
                          {
                            if(value!.isEmpty || !value.contains('@'))
                            {
                              return 'Please enter a valid Email address';
                            }
                            else
                            {
                              return null;
                            }
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText:  "Email",
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            errorBorder:  UnderlineInputBorder(
                              borderSide: BorderSide(color:  Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20,),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () =>  FocusScope.of(context).requestFocus(_phoneNumbersFocusNode),
                          keyboardType: TextInputType.visiblePassword,
                          controller: _passTextController ,
                          obscureText: !_obscureText,
                          validator: (value)
                          {
                            if(value!.isEmpty || value.length<7)
                            {
                              return 'Please enter a valid password';
                            }
                            else
                            {
                              return null;
                            }
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration:  InputDecoration(
                            suffixIcon: GestureDetector(
                              onTap: ()
                              {
                                setState((){
                                  _obscureText =!_obscureText;
                                });
                              },
                              child: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white,
                              ),
                            ),
                            hintText:  "Password",
                            hintStyle: const TextStyle(color: Colors.white),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            errorBorder:  const UnderlineInputBorder(
                              borderSide: BorderSide(color:  Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20,),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () =>  FocusScope.of(context).requestFocus(_positionCPFocusNode),
                          keyboardType: TextInputType.phone,
                          controller: _phoneNumberController ,
                          // obscureText: false,
                          validator: (value)
                          {
                            if(value!.isEmpty)
                            {
                              return 'This Field is missing';
                            }
                            else
                            {
                              return null;
                            }
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText:  "Phone Number",
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            errorBorder:  UnderlineInputBorder(
                              borderSide: BorderSide(color:  Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20,),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () =>  FocusScope.of(context).requestFocus(_positionCPFocusNode),
                          keyboardType: TextInputType.text,
                          controller: _locationController  ,
                          // obscureText: false,
                          validator: (value)
                          {
                            if(value!.isEmpty)
                            {
                              return 'This Field is missing';
                            }
                            else
                            {
                              return null;
                            }
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText:  "Company Address",
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            errorBorder:  UnderlineInputBorder(
                              borderSide: BorderSide(color:  Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25,),
                        _isLoading
                            ?
                        Center(
                          child:  Container(
                            width: 70,
                            height: 70,
                            child:  const CircularProgressIndicator(),
                          ),

                        )
                            :
                        MaterialButton(
                          onPressed: (){
                            _submitFormOnSignup();
                          },
                          color: Colors.cyan,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child:  Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'SignUp',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40,),
                        Center(
                          child:  RichText(
                            text: TextSpan(
                                children: [
                                  const TextSpan(
                                      text: 'Already have an account?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      )
                                  ),
                                  const TextSpan(
                                      text: '      '
                                  ),
                                  TextSpan(
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => Navigator.canPop(context)
                                            ?Navigator.pop(context)
                                            : null,
                                      text: 'Login',
                                      style: const TextStyle(
                                        color: Colors.cyan,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      )

                                  ),
                                ]


                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
