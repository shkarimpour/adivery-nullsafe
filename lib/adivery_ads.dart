import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class Ad {
  void show();

  void loadAd();
}

typedef NativeAdEmptyFunction = void Function();
typedef NativeAdErrorFunction = void Function(int errorCode);

typedef EmptyFunction = void Function(Ad ad);
typedef ErrorFunction = void Function(Ad ad, int errorCode);
typedef NativeAdFunction = void Function(Map<dynamic, dynamic> nativeAd);

enum BannerAdSize { BANNER, LARGE_BANNER, MEDIUM_RECTANGLE }

class BannerAd extends StatefulWidget {
  final String placementId;
  final BannerAdSize bannerType;

  final EmptyFunction? onAdLoaded;
  final ErrorFunction? onAdLoadFailed;
  final ErrorFunction? onAdShowFailed;
  final EmptyFunction? onAdClicked;

  const BannerAd({
    Key? key,
    required this.placementId,
    required this.bannerType,
    this.onAdLoaded,
    this.onAdLoadFailed,
    this.onAdShowFailed,
    this.onAdClicked,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TextViewState(
      placementId: placementId,
      bannerType: bannerType,
      onAdClicked: onAdClicked ?? (ad) {},
      onAdLoaded: onAdLoaded ?? (ad) {},
      onAdLoadFailed: onAdLoadFailed ?? (ad, err) {},
      onAdShowFailed: onAdShowFailed ?? (ad, err) {});
}

class _TextViewState extends State<BannerAd> {
  final String placementId;
  final BannerAdSize bannerType;

  final EmptyFunction? onAdLoaded;
  final ErrorFunction? onAdLoadFailed;
  final ErrorFunction? onAdShowFailed;
  final EmptyFunction? onAdClicked;

  _TextViewState({
    required this.placementId,
    required this.bannerType,
    this.onAdLoaded,
    this.onAdLoadFailed,
    this.onAdShowFailed,
    this.onAdClicked,
  }) : super();

  void _onPlatformViewCreated(int id) {
    BannerAdEventHandler handler = new BannerAdEventHandler(
        id: id,
        bannerType: bannerType,
        onAdLoaded: onAdLoaded ?? (ad) {},
        onAdClicked: onAdClicked ?? (ad) {},
        onAdShowFailed: onAdShowFailed ?? (ad, err) {},
        onAdLoadFailed: onAdLoadFailed ?? (ad, err) {});
    handler.openChannel();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return Container(
        width: getBannerWidth(bannerType),
        height: getBannerHeight(bannerType),
        child: AndroidView(
          viewType: 'adivery/bannerAd',
          creationParamsCodec: StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParams: {
            "placement_id": placementId,
            "banner_type": getBannerType()
          },
        ),
      );
    }
    return Text(
        '$defaultTargetPlatform is not yet supported by the adivery plugin');
  }

  double getBannerHeight(BannerAdSize bannerType) {
    if (bannerType == BannerAdSize.BANNER) {
      return 50;
    } else if (bannerType == BannerAdSize.LARGE_BANNER) {
      return 100;
    } else {
      return 250;
    }
  }

  double getBannerWidth(BannerAdSize bannerType) {
    if (bannerType == BannerAdSize.BANNER) {
      return 320;
    } else if (bannerType == BannerAdSize.LARGE_BANNER) {
      return 320;
    } else {
      return 300;
    }
  }

  String getBannerType() {
    if (bannerType == BannerAdSize.BANNER) {
      return "banner";
    } else if (bannerType == BannerAdSize.LARGE_BANNER) {
      return "large_banner";
    } else {
      return "medium_rectangle";
    }
  }
}

class BannerAdEventHandler extends Ad {
  final int id;
  final BannerAdSize bannerType;

  final EmptyFunction? onAdLoaded;
  final ErrorFunction? onAdLoadFailed;
  final ErrorFunction? onAdShowFailed;
  final EmptyFunction? onAdClicked;

  late MethodChannel _channel;

  BannerAdEventHandler({
    this.id: 0,
    required this.bannerType,
    this.onAdLoaded,
    this.onAdLoadFailed,
    this.onAdShowFailed,
    this.onAdClicked,
  });

  void openChannel() {
    _channel = new MethodChannel("adivery/banner_" + id.toString());
    _channel.setMethodCallHandler(handle);
  }

  Future<dynamic> handle(MethodCall call) {
    switch (call.method) {
      case "onAdLoaded":
        onAdLoaded?.call(this);
        break;
      case "onAdClicked":
        onAdClicked?.call(this);
        break;
      case "onAdLoadFailed":
        onAdLoadFailed?.call(this, call.arguments as int);
        break;
      case "onAdShowFailed":
        onAdShowFailed?.call(this, call.arguments as int);
        break;
    }
    return true as dynamic;
  }

  @override
  void loadAd() {}

  @override
  void show() {}
}

class InterstitialAd {
  static const MethodChannel _channel = const MethodChannel('adivery_plugin');
  final String placementId;
  final EmptyFunction? onAdLoaded;
  final EmptyFunction? onAdClicked;
  final EmptyFunction? onAdShown;
  final ErrorFunction? onAdShowFailed;
  final ErrorFunction? onAdLoadFailed;
  final EmptyFunction? onAdClosed;
  final String id = UniqueKey().toString();

  InterstitialAd({
    required this.placementId,
    this.onAdLoaded,
    this.onAdClicked,
    this.onAdShown,
    this.onAdShowFailed,
    this.onAdLoadFailed,
    this.onAdClosed,
  });

  late InterstitialAdEvenHandler _handler;

  void loadAd() {
    _channel
        .invokeMethod("interstitial", {"placement_id": placementId, "id": id});
    _handler = new InterstitialAdEvenHandler(
        id: id,
        placementId: placementId,
        onAdLoadFailed: onAdLoadFailed ?? (ad, err) {},
        onAdShowFailed: onAdShowFailed ?? (ad, err) {},
        onAdClicked: onAdClicked ?? (ad) {},
        onAdLoaded: onAdLoaded ?? (ad) {},
        onAdClosed: onAdClosed ?? (ad) {},
        onAdShown: onAdShown ?? (ad) {});
    _handler.openChannel();
    _handler.loadAd();
  }

  void show() {
    _handler.show();
  }

  void destroy() {
    _channel.invokeListMethod("destroyAd", id);
  }
}

class InterstitialAdEvenHandler extends Ad {
  final String placementId;
  final EmptyFunction? onAdLoaded;
  final EmptyFunction? onAdClicked;
  final EmptyFunction? onAdShown;
  final ErrorFunction? onAdShowFailed;
  final ErrorFunction? onAdLoadFailed;
  final EmptyFunction? onAdClosed;
  final String id;

  late MethodChannel _channel;

  InterstitialAdEvenHandler({
    required this.placementId,
    this.id: "",
    this.onAdLoaded,
    this.onAdClicked,
    this.onAdShown,
    this.onAdShowFailed,
    this.onAdLoadFailed,
    this.onAdClosed,
  });

  void openChannel() {
    _channel = new MethodChannel("adivery/interstitial_" + id);
    _channel.setMethodCallHandler(handle);
  }

  Future<dynamic> handle(MethodCall call) {
    switch (call.method) {
      case "onAdLoaded":
        onAdLoaded?.call(this);
        break;
      case "onAdClicked":
        onAdClicked?.call(this);
        break;
      case "onAdLoadFailed":
        onAdLoadFailed?.call(this, call.arguments as int);
        break;
      case "onAdShowFailed":
        onAdShowFailed?.call(this, call.arguments as int);
        break;
      case "onAdShown":
        onAdShown?.call(this);
        break;
      case "onAdClosed":
        onAdClosed?.call(this);
        break;
    }
    return true as dynamic;
  }

  @override
  void loadAd() {
    _channel.invokeMethod("loadAd");
  }

  @override
  void show() {
    _channel.invokeMethod("show");
  }
}

class RewardedAd {
  static const MethodChannel _channel = const MethodChannel('adivery_plugin');

  final String placementId;
  final EmptyFunction? onAdLoaded;
  final EmptyFunction? onAdClicked;
  final EmptyFunction? onAdShown;
  final ErrorFunction? onAdShowFailed;
  final ErrorFunction? onAdLoadFailed;
  final EmptyFunction? onAdClosed;
  final EmptyFunction? onAdRewarded;
  final String id = UniqueKey().toString();

  RewardedAd({
    required this.placementId,
    this.onAdLoaded,
    this.onAdClicked,
    this.onAdShown,
    this.onAdShowFailed,
    this.onAdLoadFailed,
    this.onAdClosed,
    this.onAdRewarded,
  });

  late RewardedAdEventHandler _handler;

  void loadAd() {
    _channel.invokeMethod("rewarded", {"placement_id": placementId, "id": id});
    _handler = new RewardedAdEventHandler(
        id: id,
        placementId: placementId,
        onAdLoadFailed: onAdLoadFailed,
        onAdShowFailed: onAdShowFailed,
        onAdClicked: onAdClicked,
        onAdLoaded: onAdLoaded,
        onAdClosed: onAdClosed,
        onAdShown: onAdShown,
        onAdRewarded: onAdRewarded);
    _handler.openChannel();
    _handler.loadAd();
  }

  void show() {
    _handler.show();
  }

  void destroy() {
    _channel.invokeListMethod("destroyAd", id);
  }
}

class RewardedAdEventHandler extends Ad {
  final String placementId;
  final EmptyFunction? onAdLoaded;
  final EmptyFunction? onAdClicked;
  final EmptyFunction? onAdShown;
  final ErrorFunction? onAdShowFailed;
  final ErrorFunction? onAdLoadFailed;
  final EmptyFunction? onAdClosed;
  final EmptyFunction? onAdRewarded;
  final String id;

  RewardedAdEventHandler({
    required this.placementId,
    this.id: "",
    this.onAdLoaded,
    this.onAdClicked,
    this.onAdShown,
    this.onAdShowFailed,
    this.onAdLoadFailed,
    this.onAdClosed,
    this.onAdRewarded,
  });

  late MethodChannel _channel;

  void openChannel() {
    print("opening channel");
    _channel = new MethodChannel("adivery/rewarded_" + id);
    _channel.setMethodCallHandler(handle);
  }

  Future<dynamic> handle(MethodCall call) {
    switch (call.method) {
      case "onAdLoaded":
        onAdLoaded?.call(this);
        break;
      case "onAdClicked":
        onAdClicked?.call(this);
        break;
      case "onAdLoadFailed":
        onAdLoadFailed?.call(this, call.arguments as int);
        break;
      case "onAdShowFailed":
        onAdShowFailed?.call(this, call.arguments as int);
        break;
      case "onAdShown":
        onAdShown?.call(this);
        break;
      case "onAdClosed":
        onAdClosed?.call(this);
        break;
      case "onAdRewarded":
        onAdRewarded?.call(this);
        break;
    }
    return true as dynamic;
  }

  @override
  void loadAd() {
    _channel.invokeMethod("loadAd");
  }

  @override
  void show() {
    _channel.invokeMethod("show");
  }
}

class NativeAd {
  static const MethodChannel _channel = const MethodChannel('adivery_plugin');

  final String placementId;
  final NativeAdEmptyFunction? onAdLoaded;
  final NativeAdEmptyFunction? onAdClicked;
  final NativeAdEmptyFunction? onAdShown;
  final NativeAdErrorFunction? onAdShowFailed;
  final NativeAdErrorFunction? onAdLoadFailed;
  final NativeAdEmptyFunction? onAdClosed;
  final String id = UniqueKey().toString();

  NativeAd({
    required this.placementId,
    this.onAdLoaded,
    this.onAdClosed,
    this.onAdClicked,
    this.onAdShowFailed,
    this.onAdLoadFailed,
    this.onAdShown,
  });

  late NativeAdEventHandler _handler;

  String? headline;
  String? description;
  Image? icon;
  Image? image;
  String? callToAction;
  String? advertiser;
  bool isLoaded = false;

  void loadAd() {
    _channel.invokeMethod("native", {"placement_id": placementId, "id": id});
    _handler = new NativeAdEventHandler(
        onAdLoaded: (data) {
          headline = data['headline'];
          description = data['description'];
          callToAction = data['call_to_action'];
          advertiser = data['advertiser'];
          if (data['icon'] != null) {
            Uint8List list = data['icon'];
            icon = Image.memory(list);
          }
          if (data['image'] != null) {
            Uint8List list = data['image'];
            image = Image.memory(list);
          }
          isLoaded = true;

          onAdLoaded?.call();
        },
        onAdShown: onAdShown,
        onAdClosed: onAdClosed,
        onAdClicked: onAdClicked,
        onAdShowFailed: onAdShowFailed,
        onAdLoadFailed: onAdLoadFailed,
        placementId: placementId,
        id: id);
    _handler.openChannel();
    _handler.loadAd();
  }

  void recordClick() {
    _handler.recordClick();
  }

  void destroy() {
    _channel.invokeListMethod("destroyAd", id);
  }
}

class NativeAdEventHandler {
  final String placementId;
  final NativeAdFunction? onAdLoaded;
  final NativeAdEmptyFunction? onAdClicked;
  final NativeAdEmptyFunction? onAdShown;
  final NativeAdErrorFunction? onAdShowFailed;
  final NativeAdErrorFunction? onAdLoadFailed;
  final NativeAdEmptyFunction? onAdClosed;
  final String id;

  NativeAdEventHandler({
    required this.placementId,
    this.id: "",
    this.onAdLoaded,
    this.onAdClosed,
    this.onAdClicked,
    this.onAdShowFailed,
    this.onAdLoadFailed,
    this.onAdShown,
  });

  late MethodChannel _channel;

  void openChannel() {
    _channel = new MethodChannel("adivery/native_" + id);
    _channel.setMethodCallHandler(handle);
  }

  Future<dynamic> handle(MethodCall call) {
    switch (call.method) {
      case "onAdLoaded":
        onAdLoaded?.call(call.arguments);
        break;
      case "onAdClicked":
        onAdClicked?.call();
        break;
      case "onAdLoadFailed":
        onAdLoadFailed?.call(call.arguments as int);
        break;
      case "onAdShowFailed":
        onAdShowFailed?.call(call.arguments as int);
        break;
      case "onAdShown":
        onAdShown?.call();
        break;
      case "onAdClosed":
        onAdClosed?.call();
        break;
    }
    return true as dynamic;
  }

  void loadAd() {
    _channel.invokeMethod("loadAd");
  }

  void recordClick() {
    _channel.invokeMethod("recordClick");
  }
}
