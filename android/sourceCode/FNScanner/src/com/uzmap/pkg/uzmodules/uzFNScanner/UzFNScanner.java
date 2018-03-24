/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */
package com.uzmap.pkg.uzmodules.uzFNScanner;

import java.nio.charset.Charset;
import org.json.JSONException;
import org.json.JSONObject;
import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.hardware.Camera;
import android.os.Build;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.Log;
import android.view.OrientationEventListener;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup.MarginLayoutParams;
import android.widget.AbsoluteLayout;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;

import com.google.zxing.Result;
import com.uzmap.pkg.uzcore.UZWebView;
import com.uzmap.pkg.uzcore.uzmodule.UZModule;
import com.uzmap.pkg.uzcore.uzmodule.UZModuleContext;
import com.uzmap.pkg.uzkit.UZUtility;
import com.uzmap.pkg.uzkit.data.UZWidgetInfo;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.CaptureActivity;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.CaptureView;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.camera.CameraManager;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.decoding.Utils;
import com.uzmap.pkg.uzmodules.uzFNScanner.utlis.BeepUtil;
import com.uzmap.pkg.uzmodules.uzFNScanner.utlis.JsParamsUtil;
import com.uzmap.pkg.uzmodules.uzFNScanner.utlis.ScanUtil;
import com.uzmap.pkg.uzmodules.uzFNScanner.utlis.ScannerDecoder;

@SuppressWarnings("deprecation")
public class UzFNScanner extends UZModule implements SurfaceHolder.Callback {
	public static UZModuleContext mModuleContext;
	public final int OPEN_CODE = 100;
	public final int DECODE_CODE = 300;
	private JsParamsUtil mJsParamsUtil;
	private CaptureView mCaptureView;
	private SurfaceView mSurfaceView;
	private SurfaceHolder mSurfaceHolder;
	private Camera mCamera;
	private BeepUtil mBeepUtil;
	private String mSelectedImgPath;
	private int mOrientation = 0;
	private OrientationEventListener mOrientationListener;
	private boolean mIsOrientation = false;
	public static boolean isWindow = false;

	public UzFNScanner(UZWebView webView) {
		super(webView);
	}

	public void jsmethod_openScanner(UZModuleContext moduleContext) {
		mModuleContext = moduleContext;
		isWindow = false;
		callBack(moduleContext);//remove by cameracheck at 2017年9月1日17:51:31
		mJsParamsUtil = JsParamsUtil.getInstance();
		stopCamera();
		Intent intent = new Intent(getContext(), CaptureActivity.class);
		initIntentParams(moduleContext, intent);
		intent.putExtra("isNewUI", false);
		startActivityForResult(this, intent, OPEN_CODE);
	}
	
	public void jsmethod_open(UZModuleContext moduleContext) {
		mModuleContext = moduleContext;
		isWindow = false;
		callBack(moduleContext);//remove by cameracheck at 2017年9月1日17:51:31
		mJsParamsUtil = JsParamsUtil.getInstance();
		stopCamera();
		Intent intent = new Intent(getContext(), CaptureActivity.class);
		initIntentParams(moduleContext, intent);
		intent.putExtra("isNewUI", true);
		startActivityForResult(this, intent, OPEN_CODE);
	}

	public void jsmethod_openView(UZModuleContext moduleContext) {
		mModuleContext = moduleContext;
		isWindow = true;
		mJsParamsUtil = JsParamsUtil.getInstance();
		callBack(moduleContext);//remove by cameracheck at 2017年9月1日17:51:31
		openDIYScanner(moduleContext);
		mIsOrientation = moduleContext.optBoolean("autorotation", false);
		if (mIsOrientation) {
			initOrientation();
			startOrientationChangeListener();
		}
	}

	public void jsmethod_setFrame(UZModuleContext moduleContext) {
		mJsParamsUtil = JsParamsUtil.getInstance();
		resetLayout(moduleContext);
	}

	public void jsmethod_closeView(UZModuleContext moduleContext) {
		destroyCamera();
		removePreView();
	}

	public void jsmethod_decodeImg(UZModuleContext moduleContext) {
		mModuleContext = moduleContext;
		mJsParamsUtil = JsParamsUtil.getInstance();
		String sound = mJsParamsUtil.sound(moduleContext);
		sound = makeRealPath(sound);
		mBeepUtil = new BeepUtil(mContext, sound);
		mBeepUtil.initBeep();
		decode(moduleContext);
	}

	public void jsmethod_encodeImg(UZModuleContext moduleContext) {
		mModuleContext = moduleContext;
		mJsParamsUtil = JsParamsUtil.getInstance();
		String savePath = encode(moduleContext);
		encodeCallBack(moduleContext, savePath, ScanUtil.ALBUM_IMG_PATH);
	}
	
	public void jsmethod_switchLight(UZModuleContext moduleContext) {
		mJsParamsUtil = JsParamsUtil.getInstance();
		//CameraManager.init(mContext);
		switchLight(moduleContext);
	}
	
	public void jsmethod_onResume(UZModuleContext moduleContext) {
		if(mCaptureView!= null){
			mCaptureView.onResume();
		}
	}
	public void jsmethod_onPause(UZModuleContext moduleContext) {
		if(mCaptureView!= null){
			mCaptureView.onPause();
		}
	}

	private void callBack(UZModuleContext moduleContext) {
		JSONObject ret = new JSONObject();
		try {
			ret.put("eventType", "show");
			moduleContext.success(ret, false);
		} catch (JSONException e) {
			e.printStackTrace();
		}
	}

	public void openDIYScanner(UZModuleContext moduleContext) {
		stopCamera();
		removePreView();
		initCaptureView(moduleContext);
		initParams(moduleContext);
		insertCaptureView(moduleContext);
		mCaptureView.onResume();
	}

	private void switchLight(UZModuleContext moduleContext) {
		try {
			int currentapiVersion = Build.VERSION.SDK_INT;
			if (currentapiVersion < 21) {
				lightSwitchLower21(lightStatus(moduleContext));
			} else {
				lightSwitch(lightStatus(moduleContext));
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private boolean lightStatus(UZModuleContext moduleContext) {
		String status = moduleContext.optString("status", "off");
		boolean isTurnOn = false;
		if (status.equals("on")) {
			isTurnOn = true;
		} else {
			isTurnOn = false;
		}
		return isTurnOn;
	}

	private void lightSwitchLower21(boolean isTurnOn) {
		if (isTurnOn) {
			if (mCaptureView == null) {
				if (mCamera == null) {
						mCamera = Camera.open();
				}
				Camera.Parameters mparameter = mCamera.getParameters();
				mparameter.setFlashMode("torch");
				mCamera.setParameters(mparameter);
			} else {
				CameraManager.get().openLight();
			}
		} else if (mCaptureView == null) {
			Camera.Parameters parameter = mCamera.getParameters();
			parameter.setFlashMode("off");
			mCamera.setParameters(parameter);
		} else {
			CameraManager.get().offLight();
		}
	}

	private void lightSwitch(boolean isTurnOn) {
		if (mCaptureView != null) {
			if (isTurnOn)
				CameraManager.get().openLight();
			else
				CameraManager.get().offLight();
		} else {
			if (mSurfaceView != null) {
				removeViewFromCurWindow(mSurfaceView);
				mSurfaceView = null;
			}
			stopCamera();
			mSurfaceView = new SurfaceView(mContext);
			mSurfaceHolder = mSurfaceView.getHolder();
			mSurfaceHolder.addCallback(this);
			mSurfaceHolder.setType(3);
			RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
					1, 1);
			insertViewToCurWindow(mSurfaceView, params);
		}
	}

	private String encode(UZModuleContext moduleContext) {
		String content = mJsParamsUtil.encodeContent(moduleContext);
		boolean isBar = mJsParamsUtil.isBar(moduleContext);
		boolean isSaveToAlbum = mJsParamsUtil.saveToAlbum(moduleContext);
		String savePath = mJsParamsUtil.saveImgPath(moduleContext);
		savePath = makeRealPath(savePath);
		int saveW = mJsParamsUtil.saveImgW(moduleContext);
		int saveH = mJsParamsUtil.saveImgH(moduleContext);
		return ScanUtil.scanResult2img(content, savePath, saveW, saveH,
				isSaveToAlbum, isBar, mContext);
	}

	private void decode(UZModuleContext moduleContext) {
		String imgPath = mJsParamsUtil.decodePath(moduleContext);
		if (TextUtils.isEmpty(imgPath)) {
			selectImgFromSystem();
		} else {
			decodeImg(imgPath);
		}
	}

	private void decodeImg(String imgPath) {
		imgPath = UZUtility.makeRealPath(imgPath, getWidgetInfo());
		final String path = makeRealPath(imgPath);
		if (!TextUtils.isEmpty(path)) {
			new Thread(new Runnable() {
				public void run() {
					Result result = ScannerDecoder.decodeBar(path);
					mBeepUtil.playBeepSoundAndVibrate();
					if (result == null) {
						decodeCallBack(false, null);
					} else {
						decodeCallBack(true, result.toString());
					}
				}
			}).start();
		}
	}

	private void selectImgFromSystem() {
		Intent innerIntent = new Intent();
		if (Build.VERSION.SDK_INT < 19)
			innerIntent.setAction("android.intent.action.GET_CONTENT");
		else {
			innerIntent.setAction("android.intent.action.OPEN_DOCUMENT");
		}
		innerIntent.setType("image/*");
		startActivityForResult(innerIntent, DECODE_CODE);
	}

	private void initCaptureView(UZModuleContext moduleContext) {
		mCaptureView = new CaptureView(mContext, this, moduleContext);
	}

	public void insertCaptureView(UZModuleContext moduleContext) {
		String fixedOn = moduleContext.optString("fixedOn");
		boolean fixed = moduleContext.optBoolean("fixed", true);
		
		insertViewToCurWindow(mCaptureView, captureViewLayout(moduleContext),
				fixedOn, fixed);
	}

	private RelativeLayout.LayoutParams captureViewLayout(
			UZModuleContext moduleContext) {
		int x = mJsParamsUtil.x(moduleContext);
		int y = mJsParamsUtil.y(moduleContext);
		int width = mJsParamsUtil.w(moduleContext, mContext);
		int height = mJsParamsUtil.h(moduleContext, mContext, this);
		RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(width, height);
		params.setMargins(x, y, 0, 0);
		return params;
	}

	private void resetLayout(UZModuleContext moduleContext) {
		int x = UZUtility.dipToPix(moduleContext.optInt("x"));
		int y = UZUtility.dipToPix(moduleContext.optInt("y"));
		int w = UZUtility.dipToPix(moduleContext.optInt("w"));
		int h = UZUtility.dipToPix(moduleContext.optInt("h"));
		if (mCaptureView.getLayoutParams() instanceof FrameLayout.LayoutParams) {
			FrameLayout.LayoutParams p = new FrameLayout.LayoutParams(w, h);
			p.setMargins(x, y, 0, 0);
			mCaptureView.setLayoutParams(p);
		} else if (mCaptureView.getLayoutParams() instanceof MarginLayoutParams) {
			LayoutParams p = new LayoutParams(w, h);
			p.setMargins(x, y, 0, 0);
			mCaptureView.setLayoutParams(p);
		} else {
			AbsoluteLayout.LayoutParams p = new AbsoluteLayout.LayoutParams(w,
					h, x, y);
			mCaptureView.setLayoutParams(p);
		}
	}

	private void initIntentParams(UZModuleContext moduleContext, Intent intent) {
		String sound = mJsParamsUtil.sound(moduleContext);
		sound = makeRealPath(sound);
		boolean isSaveToAlbum = mJsParamsUtil.saveToAlbum(moduleContext);
		String savePath = mJsParamsUtil.saveImgPath(moduleContext);
		boolean autorotation = moduleContext.optBoolean("autorotation", false);
		savePath = makeRealPath(savePath);
		int saveW = mJsParamsUtil.saveImgW(moduleContext);
		int saveH = mJsParamsUtil.saveImgH(moduleContext);
		intent.putExtra("soundPath", sound);
		intent.putExtra("isSaveToAlbum", isSaveToAlbum);
		intent.putExtra("savePath", savePath);
		intent.putExtra("saveW", saveW);
		intent.putExtra("saveH", saveH);
		intent.putExtra("autorotation", autorotation);
	}

	private void initParams(UZModuleContext moduleContext) {
		String sound = mJsParamsUtil.sound(moduleContext);
		sound = makeRealPath(sound);
		boolean isSaveToAlbum = mJsParamsUtil.saveToAlbum(moduleContext);
		String savePath = mJsParamsUtil.saveImgPath(moduleContext);
		savePath = makeRealPath(savePath);
		int saveW = mJsParamsUtil.saveImgW(moduleContext);
		int saveH = mJsParamsUtil.saveImgH(moduleContext);
		mCaptureView.initParams(savePath, saveW, saveH, sound, isSaveToAlbum);
	}

	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);
		if (resultCode == Activity.RESULT_OK) {
			callBack(mModuleContext);
			switch (requestCode) {
			case OPEN_CODE:
				onOpenParseResult(data);
				break;
			case DECODE_CODE:
				onDecodeParseResult(data);
				break;
			}
		}
	}

	private void onDecodeParseResult(Intent data) {
		initSelectedImgPath(data);
		parseImg();
	}

	private void initSelectedImgPath(Intent data) {
		String[] proj = { MediaStore.Images.Media.DATA };
		Cursor cursor = mContext.getContentResolver().query(data.getData(),
				proj, null, null, null);
		if (cursor.moveToFirst()) {
			int column_index = cursor
					.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
			mSelectedImgPath = cursor.getString(column_index);
			if (mSelectedImgPath == null) {
				mSelectedImgPath = Utils.getPath(mContext, data.getData());
			}
		}
		cursor.close();
	}

	private void parseImg() {
		new Thread(mParseImgRunable).start();
	}

	private Runnable mParseImgRunable = new Runnable() {
		@Override
		public void run() {
			Result result = ScannerDecoder.decodeBar(mSelectedImgPath);
			mBeepUtil.playBeepSoundAndVibrate();
			if (result == null) {
				decodeCallBack(false, null);
			} else {
				decodeCallBack(true, result.toString());
			}
		}
	};

	private void onOpenParseResult(Intent data) {
		String GB_Str = "";
		try {
			if (data != null) {
				String stringExtra = data.getStringExtra("result");
				String savePath = data.getStringExtra("savePath");
				String albumPath = data.getStringExtra("albumPath");
				boolean ISO = Charset.forName("ISO-8859-1").newEncoder()
						.canEncode(stringExtra);
				if (ISO) {
					GB_Str = new String(stringExtra.getBytes("ISO-8859-1"),
							"GB2312");
					openCallback(GB_Str, "success", savePath, albumPath);
				} else {
					openCallback(stringExtra, "success", savePath, albumPath);
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private void openCallback(String result, String eventType, String savePath,
			String albumPath) {
		JSONObject object = new JSONObject();
		try {
			object.put("eventType", eventType);
			if (savePath != null)
				object.put("imgPath", savePath);
			if (albumPath != null)
				object.put("albumPath", albumPath);
			object.put("content", result);
			mModuleContext.success(object, false);
		} catch (JSONException e) {
			e.printStackTrace();
		}
	}

	private void decodeCallBack(boolean status, String content) {
		JSONObject ret = new JSONObject();
		try {
			ret.put("status", status);
			if (status) {
				ret.put("content", content);
			}
			mModuleContext.success(ret, false);
		} catch (JSONException e) {
			e.printStackTrace();
		}
	}

	private void encodeCallBack(UZModuleContext moduleContext, String savePath,
			String albumPath) {
		JSONObject ret = new JSONObject();
		try {
			ret.put("imgPath", savePath);
			if (albumPath != null)
				ret.put("albumPath", albumPath);
			ret.put("status", true);
			moduleContext.success(ret, false);
		} catch (JSONException e) {
			e.printStackTrace();
		}
	}

	private void removePreView() {
		if (mCaptureView != null) {
			mCaptureView.onPause();
			mCaptureView.onDestroy();
			removeViewFromCurWindow(mCaptureView);
			mCaptureView = null;
		}
	}

	@Override
	public void surfaceCreated(SurfaceHolder holder) {
		try {
			if (mCamera == null) {
					mCamera = Camera.open();
			}
			mCamera.setPreviewDisplay(mSurfaceHolder);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	@Override
	public void surfaceChanged(SurfaceHolder holder, int format, int width,
			int height) {

	}

	@Override
	public void surfaceDestroyed(SurfaceHolder holder) {
		destroyCamera();
	}

	private void stopCamera() {
		if (mSurfaceView != null) {
			removeViewFromCurWindow(mSurfaceView);
			mSurfaceView = null;
		}
		destroyCamera();
	}

	protected void onClean() {
		destroyCamera();
		removePreView();
		if (mSurfaceView != null) {
			removeViewFromCurWindow(mSurfaceView);
			mSurfaceView = null;
		}
		super.onClean();
	}

	private void destroyCamera() {
		if (mCamera != null) {
			mCamera.stopPreview();
			mCamera.release();
			mCamera = null;
		}
	}

	private void initOrientation() {
		int angle = getDisplayRotation();
		switch (angle) {
		case 90:
			mOrientation = 0;
			break;
		case 0:
			mOrientation = 1;
			break;
		case 270:
			mOrientation = 2;
			break;
		case 180:
			mOrientation = 3;
		}
	}

	public int getDisplayRotation() {
		if (mContext == null || mContext.getWindowManager() == null) {
			return 0;
		}
		int rotation = mContext.getWindowManager().getDefaultDisplay()
				.getRotation();
		switch (rotation) {
		case Surface.ROTATION_0:// 涓�
			return 90;
		case Surface.ROTATION_90:// 宸�
			return 0;
		case Surface.ROTATION_180:// 涓�
			return 270;
		case Surface.ROTATION_270:// 鍙�
			return 180;
		}
		return 0;
	}

	private final void startOrientationChangeListener() {
		this.mOrientationListener = new OrientationEventListener(mContext) {
			public void onOrientationChanged(int rotation) {
				synchronized (mOrientationListener) {
					int angle = getDisplayRotation();
					if (angle == 0) {
						if (mOrientation != 1) {
							chargeScreenAngle();
						}
						mOrientation = 1;
					} else if (angle == 180) {
						if (mOrientation != 3) {
							chargeScreenAngle();
						}
						mOrientation = 3;
					} else if (angle == 90) {
						if (mOrientation != 0) {
							chargeScreenAngle();
						}
						mOrientation = 0;
					} else if (angle == 270) {
						if (mOrientation != 2) {
							chargeScreenAngle();
						}
						mOrientation = 2;
					}
				}
			}
		};
		this.mOrientationListener.enable();
	}

	private void chargeScreenAngle() {
		int angle = getDisplayRotation();
		if (CameraManager.get() != null)
			CameraManager.get().setScreemOrientation(angle);
	}

	public void checkOpenCameraCallback(CaptureView captureView){
		if(mModuleContext != null){
			JSONObject ret = new JSONObject();
			try {
				ret.put("eventType", "cameraError");
				mModuleContext.success(ret, false);
			} catch (JSONException e2) {
				e2.printStackTrace();
			}
		}
	}
	
}
