import 'package:country_list_pick/country_list_pick.dart';
import 'package:eco_collect/api/firebase_apis.dart';
import 'package:eco_collect/components/buttons/reusable_button.dart';
import 'package:eco_collect/components/reusable_bg_image.dart';
import 'package:eco_collect/constants/error_handler_values.dart';
import 'package:eco_collect/constants/kassets.dart';

import 'package:eco_collect/constants/ktheme.dart';
import 'package:eco_collect/providers/user_provider.dart';
import 'package:eco_collect/routes/kroutes.dart';

import 'package:eco_collect/screens/mother_earth_video.dart/mother_earth_video.dart';
import 'package:eco_collect/screens/global/global_bottom_nav.dart';
import 'package:eco_collect/utils/common_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:eco_collect/components/reusable_textformfield.dart';

import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _regFormKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;

  String _country = 'Tunisia'; // Hardcoded for backward compatibility
  String _campus = 'Manouba School of Engineering';
  final List<String> _campuses = [
    'Manouba School of Engineering',
    'École Nationale des Sciences Informatiques',
    'Business/Finance School'
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(),
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              const ReusableBgImage(
                assetImageSource: KLottie.nightRiverBoatMountains,
                isLottie: true,
              ),
              LottieBuilder.asset(KLottie.parrots),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: KTheme.transparencyBlack),
                          child: const Text(
                            'Register',
                            style: KTheme.titleStyle,
                          ),
                        ),
                        Hero(
                          tag: 'authEarth',
                          child: Lottie.asset(
                            KLottie.earthHeadphones,
                            height: 60.0,
                            width: 60.0,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                        child: Center(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Form(
                            key: _regFormKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              children: [
                                ReusableTextFormField(
                                  controller: _fullNameController,
                                  textInputAction: TextInputAction.next,
                                  label: 'Full name',
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z\s]')),
                                  ],
                                ),
                                Commonfunctions.gapMultiplier(),
                                ReusableTextFormField(
                                  controller: _usernameController,
                                  textInputAction: TextInputAction.next,
                                  label: 'username',
                                  suffixIcon: const Icon(Icons.alternate_email),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z\d]')),
                                  ],
                                ),
                                Commonfunctions.gapMultiplier(),
                                ReusableTextFormField(
                                  controller: _emailController,
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.emailAddress,
                                  label: 'Email',
                                  suffixIcon: const Icon(Icons.email),
                                  addEmailValidation: true,
                                ),
                                Commonfunctions.gapMultiplier(),
                                ReusableTextFormField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  textInputAction: TextInputAction.next,
                                  validator: (value) => _passwordValidation(
                                      value, _passwordController),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        isPasswordHidden = !isPasswordHidden;
                                      });
                                    },
                                    icon: isPasswordHidden
                                        ? const Icon(Icons.remove_red_eye)
                                        : const Icon(Icons.emergency),
                                  ),
                                  obscureText: isPasswordHidden,
                                ),
                                Commonfunctions.gapMultiplier(),
                                ReusableTextFormField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm Password',
                                  textInputAction: TextInputAction.next,
                                  validator: (value) => _passwordValidation(
                                      value, _confirmPasswordController),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        isConfirmPasswordHidden =
                                            !isConfirmPasswordHidden;
                                      });
                                    },
                                    icon: isConfirmPasswordHidden
                                        ? const Icon(Icons.remove_red_eye)
                                        : const Icon(Icons.emergency),
                                  ),
                                  obscureText: isConfirmPasswordHidden,
                                ),
                                Commonfunctions.gapMultiplier(),
                                DropdownButtonFormField<String>(
                                  value: _campus,
                                  dropdownColor: Colors.black87,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Select your Campus/Faculty',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: KTheme.transparencyBlack,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  icon: const Icon(Icons.school, color: Colors.white),
                                  items: _campuses.map((String campusName) {
                                    return DropdownMenuItem<String>(
                                      value: campusName,
                                      child: Text(campusName),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _campus = newValue!;
                                    });
                                  },
                                ),
                                Commonfunctions.gapMultiplier(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: ReusableButton(
                                    label: 'Register',
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    onTap: _submitForm,
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _passwordValidation(value, TextEditingController controller) {
    if (controller.text.trim().length < 8 ||
        controller.text.trim().length > 16) {
      return "It should be 8 to 16 characters long.";
    } else if (_confirmPasswordController.text.trim() !=
        _passwordController.text.trim()) {
      return 'Password not matching';
    }
    return null;
  }

  void _submitForm() async {
    if (_regFormKey.currentState!.validate()) {
      final res = await FirebaseApis().registerFirebase(
        context: context,
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        emailAddress: _emailController.text.trim(),
        country: _country,
        password: _passwordController.text.trim(),
      );
      if (res == ErrorsHandlerValues.goodToRegister) {
        // If all things went successfully
        Provider.of<UserDataProvider>(navigatorKey.currentContext!,
                listen: false)
            .setIsFirstTimeUser = true;
        KRoute.pushRemove(
            context: navigatorKey.currentContext!,
            page: const GlobalBottomNav());
      }
    }
  }
}
