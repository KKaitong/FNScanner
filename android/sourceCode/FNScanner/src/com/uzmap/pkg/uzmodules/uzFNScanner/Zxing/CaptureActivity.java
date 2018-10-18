/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */
package com.uzmap.pkg.uzmodules.uzFNScanner.Zxing;

import java.io.File;
import java.util.Observer;

import org.json.JSONException;
import org.json.JSONObject;
import org.simple.eventbus.EventBus;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Rect;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.provider.MediaStore;
import android.util.Log;
import android.view.Display;
import android.view.OrientationEventListener;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;
import android.widget.TextView;
import android.widget.Toast;
import android.view.SurfaceHolder.Callback;
import android.view.SurfaceView;
import android.view.View;
import android.view.View.OnClickListener;
import com.google.zxing.Result;
import com.uzmap.pkg.uzcore.UZResourcesIDFinder;
import com.uzmap.pkg.uzkit.UZUtility;
import com.uzmap.pkg.uzmodules.uzFNScanner.UzFNScanner;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.camera.CameraManager;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.decoding.CaptureActivityHandler;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.decoding.InactivityTimer;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.decoding.Utils;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.view.ViewfinderView;
import com.uzmap.pkg.uzmodules.uzFNScanner.utlis.BeepUtil;
import com.uzmap.pkg.uzmodules.uzFNScanner.utlis.ScanUtil;
import com.uzmap.pkg.uzmodules.uzFNScanner.utlis.ScannerDecoder;

public class CaptureActivity extends Activity implements Callback, OnClickListener {
	private static final int REQUEST_CODE = 234;
	private CaptureActivityHandler mHandler;
	private ViewfinderView mViewfinderView;
	private InactivityTimer mInactivityTimer;
	private String mSelectedImgPath;
	private String mSavePath;
	private int mSaveW;
	private int mSaveH;
	private String mBeepPath;
	private boolean mIsSaveToAlbum;
	private boolean mHasSurface;
	private boolean mSwitchLigthFlag = true;
	private BeepUtil mBeepUtil;
	private int mOrientation = 0;
	private OrientationEventListener mOrientationListener;
	private boolean mIsOrientation = false;
	private RelativeLayout mRlRoot;
	private boolean isNewUI;

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		int rotation = getDisplayRotation();
		Intent intent = getIntent();
		isNewUI = intent.getBooleanExtra("isNewUI", true);
		String lineColor = intent.getStringExtra("lineColor");
		if (isNewUI) {
			if (rotation == 90) {
				setContentView(getLayoutId());
			}else {
				setContentView(UZResourcesIDFinder.getResLayoutID("activity_land_scanner"));
			}
		}else {
			if (rotation == 90) {
				setContentView(UZResourcesIDFinder.getResLayoutID("activity_open_scanner"));
			}else {
				setContentView(UZResourcesIDFinder.getResLayoutID("activity_open_land_scanner"));
			}
		}
		
		init();
		initParams();
		initView(lineColor);
		//setOrientation();
		initOrientation();
		
		startOrientationChangeListener();
		EventBus.getDefault().register(this);
	}
	
	public static boolean mOrientationFlag = true;
	public static String RESET_ORIENTATION = "reset_orientation";
	private void setOrientation() {
		boolean orientationFlag = true;
        int screenState = CaptureActivity.this.getResources().getConfiguration().orientation;
        if (screenState == Configuration.ORIENTATION_LANDSCAPE){
            mOrientationFlag = false;
            orientationFlag = false;
        } else if (screenState ==Configuration.ORIENTATION_PORTRAIT) {
            mOrientationFlag = true;
            orientationFlag = true;
        }
        EventBus.getDefault().post(orientationFlag, RESET_ORIENTATION);
    }
	
	public static boolean getOrientationFlag() {
        return mOrientationFlag;
    }

	private void init() {
		CameraManager.init(getApplication());
		mHasSurface = false;
		mInactivityTimer = new InactivityTimer(this);
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

	private void initView(String lineColor) {
		mViewfinderView = (ViewfinderView) findViewById(finderViewId());
		mViewfinderView.setLineColor(lineColor);
		mRlRoot = (RelativeLayout) findViewById(UZResourcesIDFinder.getResIdID("rl_root"));
		findViewById(backBtnId()).setOnClickListener(this);
		findViewById(selectImgBtnId()).setOnClickListener(this);
		findViewById(switchLightBtnId()).setOnClickListener(this);
	}

	private void initParams() {
		Intent intent = getIntent();
		mBeepPath = intent.getStringExtra("soundPath");
		mBeepUtil = new BeepUtil(this, mBeepPath);
		mIsSaveToAlbum = intent.getBooleanExtra("isSaveToAlbum", false);
		mSavePath = intent.getStringExtra("savePath");
		mSaveW = intent.getIntExtra("saveW", 200);
		mSaveH = intent.getIntExtra("saveH", 200);
		mIsOrientation = intent.getBooleanExtra("autorotation", false);
	}

	@Override
	public void onClick(View v) {
		if (v.getId() == backBtnId()) {
			callBack("cancel", null);
			finish();
		} else if (v.getId() == selectImgBtnId()) {
			callBack("selectImage", null);
			selectImg();
		} else if (v.getId() == switchLightBtnId()) {
			switchLight();
		}
	}

	@SuppressLint("InlinedApi")
	private void selectImg() {
		Intent innerIntent = new Intent();
		if (Build.VERSION.SDK_INT < 19) {
			innerIntent.setAction(Intent.ACTION_GET_CONTENT);
		} else {
			innerIntent.setAction(Intent.ACTION_OPEN_DOCUMENT);
		}
		innerIntent.setType("image/*");
		Intent wrapperIntent = Intent.createChooser(innerIntent, "选择二维码图片");
		startActivityForResult(wrapperIntent, REQUEST_CODE);
	}

	private void switchLight() {
		if (mSwitchLigthFlag == true) {
			mSwitchLigthFlag = false;
			CameraManager.get().openLight();
		} else {
			mSwitchLigthFlag = true;
			CameraManager.get().offLight();
		}
	}

	public void handleDecode(final Result obj, Bitmap barcode) {
//		mInactivityTimer.onActivity();
		 mBeepUtil.playBeepSoundAndVibrate();
		String savePath = null;
		ScanUtil.scanResult2img(obj.getText(), mSavePath, mSaveW, mSaveH,
				mIsSaveToAlbum, false, this);
		if (!isBlank(mSavePath)) {
			savePath = new File(mSavePath).getAbsolutePath();
		}
		handleDecodeFinish(savePath, ScanUtil.ALBUM_IMG_PATH, obj);
	}

	private void handleDecodeFinish(String savePath, String albumPath,
			final Result obj) {
		Intent data = new Intent();
		if (savePath != null)
			data.putExtra("savePath", savePath);
		if (albumPath != null)
			data.putExtra("albumPath", albumPath);
		data.putExtra("result", obj.toString());
		setResult(RESULT_OK, data);
		
		finish();
	}

	private void backPreAct(Result result) {
		Intent data = new Intent();
		data.putExtra("result", result.toString());
		setResult(RESULT_OK, data);
		finish();
	}

	private void initSelectedImgPath(Intent data) {
		String[] proj = { MediaStore.Images.Media.DATA };
		Cursor cursor = getContentResolver().query(data.getData(), proj, null,
				null, null);
		if (cursor.moveToFirst()) {
			int column_index = cursor
					.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
			mSelectedImgPath = cursor.getString(column_index);
			if (mSelectedImgPath == null) {
				mSelectedImgPath = Utils.getPath(getApplicationContext(),
						data.getData());
			}
		}
		cursor.close();
	}

	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);
		if (resultCode == RESULT_OK) {
			switch (requestCode) {
			case REQUEST_CODE:
				initSelectedImgPath(data);
				parseImg();
				break;
			}
		}
	}

	private void parseImg() {
		new Thread(mParseImgRunable).start();
	}

	private Runnable mParseImgRunable = new Runnable() {
		@Override
		public void run() {
			Result result = ScannerDecoder.decodeBar(mSelectedImgPath);
			if (result == null) {
				callBack("fail", "非法图片");
				finish();
			} else {
				backPreAct(result);
			}
		}
	};

	@Override
	protected void onResume() {
		setOrientation();
		if (!mIsOrientation) {
			if (getRequestedOrientation() != ActivityInfo.SCREEN_ORIENTATION_PORTRAIT) {
				setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
			}
		}
		super.onResume();
		initOnResume();
	}

	private void initOnResume() {
		initSurface();
		mBeepUtil.initBeep();
	}

	@SuppressWarnings("deprecation")
	private void initSurface() {
		SurfaceView surfaceView = (SurfaceView) findViewById(preViewId());
		SurfaceHolder surfaceHolder = surfaceView.getHolder();
		if (mHasSurface) {
			initCamera(surfaceHolder);
		} else {
			surfaceHolder.addCallback(this);
			surfaceHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
		}
	}

	@SuppressWarnings("deprecation")
	private void initCamera(SurfaceHolder surfaceHolder) {
		try {
			WindowManager manager = (WindowManager) getSystemService(Context.WINDOW_SERVICE);
			Display display = manager.getDefaultDisplay();
			CameraManager.get().openDriver(surfaceHolder, display.getWidth(), display.getHeight(), false);
			chargeScreenAngle();
		} catch (Exception e) {
			//check camera  begin
			if(UzFNScanner.mModuleContext != null){
				JSONObject ret = new JSONObject();
				try {
					ret.put("eventType", "cameraError");
					UzFNScanner.mModuleContext.success(ret, false);
					finish();
				} catch (JSONException e2) {
					e2.printStackTrace();
				}
			}
			//check camera end add by at 2017-09-01 17:56:12
			return;
		}
		if (mHandler == null) {
			mHandler = new CaptureActivityHandler(this, null, null);
		}
	}

	private void chargeScreenAngle() {
		int angle = getDisplayRotation();
		CameraManager.get().setScreemOrientation(angle);
	}

	@Override
	protected void onPause() {
		super.onPause();
		if (mHandler != null) {
			mHandler.quitSynchronously();
			mHandler = null;
		}
		if (!mHasSurface) {
			SurfaceView surfaceView = (SurfaceView) findViewById(preViewId());
			SurfaceHolder surfaceHolder = surfaceView.getHolder();
			surfaceHolder.removeCallback(this);
		}
		CameraManager.get().closeDriver();
	}

	@Override
	protected void onDestroy() {
		mInactivityTimer.shutdown();
		super.onDestroy();
	}

	private void callBack(String eventType, String msg) {
		JSONObject ret = new JSONObject();
		try {
			ret.put("eventType", eventType);
			if (msg != null)
				ret.put("content", msg);
			UzFNScanner.mModuleContext.success(ret, false);
		} catch (JSONException e) {
			e.printStackTrace();
		}
	}

	private int getLayoutId() {
		return UZResourcesIDFinder.getResLayoutID("activity_scanner");
		//return UZResourcesIDFinder.getResLayoutID("mo_fnscanner_main");
	}

	private int finderViewId() {
		return UZResourcesIDFinder.getResIdID("mo_fnscanner_viewfinder_view");
	}

	private int backBtnId() {
		return UZResourcesIDFinder.getResIdID("mo_fnscanner_back");
	}

	private int selectImgBtnId() {
		return UZResourcesIDFinder.getResIdID("mo_fnscanner_photo");
	}

	private int switchLightBtnId() {
		return UZResourcesIDFinder.getResIdID("mo_fnscanner_light");
	}

	private int preViewId() {
		return UZResourcesIDFinder.getResIdID("mo_fnscanner_preview_view");
	}

	@Override
	public void surfaceChanged(SurfaceHolder holder, int format, int width,
			int height) {
	}

	@Override
	public void surfaceCreated(SurfaceHolder holder) {
		if (!mHasSurface) {
			mHasSurface = true;
			initCamera(holder);
			if (isNewUI) {
				Rect frame;
				int rotation = getDisplayRotation();
				if (rotation == 90) {
					frame = CameraManager.get().getFramingRect();
				}else {
					frame = CameraManager.get().getLandFramingRect();
				}
				if (frame != null) {
					addFlash(frame);
				}
			}
		}
	}
	
	private void addFlash(Rect frame) {
		RelativeLayout flashRoot = new RelativeLayout(this);
		RelativeLayout.LayoutParams flashParams = new LayoutParams(UZUtility.dipToPix(40), UZUtility.dipToPix(33));
		flashParams.leftMargin = frame.left + frame.width() / 2 - UZUtility.dipToPix(40) / 2;
		flashParams.topMargin = frame.bottom - UZUtility.dipToPix(40);
		flashRoot.setLayoutParams(flashParams);
		
		final ImageView ivFlash = new ImageView(this);
		RelativeLayout.LayoutParams ivflashParams = new LayoutParams(UZUtility.dipToPix(20), UZUtility.dipToPix(20));
		ivflashParams.addRule(RelativeLayout.CENTER_HORIZONTAL);
		ivFlash.setLayoutParams(ivflashParams);
		ivFlash.setImageResource(UZResourcesIDFinder.getResDrawableID("mo_flash_off"));
		flashRoot.addView(ivFlash);
		
		final TextView flash_state = new TextView(this);
		RelativeLayout.LayoutParams tvParams = new LayoutParams(-2, -2);
		tvParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
		tvParams.addRule(RelativeLayout.CENTER_HORIZONTAL);
		flash_state.setLayoutParams(tvParams);
		flash_state.setText("轻触照亮");
		flash_state.setTextColor(Color.parseColor("#ffffff"));
		flash_state.setTextSize(10);
		flashRoot.addView(flash_state);
		
		mRlRoot.addView(flashRoot);
		
		flashRoot.setOnClickListener(new OnClickListener() {
			
			@Override
			public void onClick(View v) {
				if (mSwitchLigthFlag == true) {
					mSwitchLigthFlag = false;
					ivFlash.setImageResource(UZResourcesIDFinder.getResDrawableID("mo_flash_on"));
					flash_state.setText("轻触关闭");
					CameraManager.get().openLight();
				} else {
					mSwitchLigthFlag = true;
					ivFlash.setImageResource(UZResourcesIDFinder.getResDrawableID("mo_flash_off"));
					flash_state.setText("轻触照亮");
					CameraManager.get().offLight();
				}
			}
		});
	}

	@Override
	public void surfaceDestroyed(SurfaceHolder holder) {
		mHasSurface = false;
	}

	public ViewfinderView getViewfinderView() {
		return mViewfinderView;
	}

	public Handler getHandler() {
		return mHandler;
	}

	public boolean isBlank(CharSequence cs) {
		int strLen;
		if ((cs == null) || ((strLen = cs.length()) == 0))
			return true;
		for (int i = 0; i < strLen; i++) {
			if (!Character.isWhitespace(cs.charAt(i))) {
				return false;
			}
		}
		return true;
	}

	@Override
	public void onBackPressed() {
		super.onBackPressed();
		callBack("cancel", null);
	}

	public int getDisplayRotation() {
		int rotation = getWindowManager().getDefaultDisplay().getRotation();
		switch (rotation) {
		case Surface.ROTATION_0:// 上
			return 90;
		case Surface.ROTATION_90:// 左
			return 0;
		case Surface.ROTATION_180:// 下
			return 270;
		case Surface.ROTATION_270:// 右
			return 180;
		}
		return 0;
	}

	/**
	 * 屏幕变换的监听
	 */
	private final void startOrientationChangeListener() {
		this.mOrientationListener = new OrientationEventListener(this) {
			public void onOrientationChanged(int rotation) {
				synchronized (mOrientationListener) {
					int angle = getDisplayRotation();
					if (angle == 0) {
						if (mOrientation == 3) {
							chargeScreenAngle();
						}
						mOrientation = 1;
					} else if (angle == 180) {
						if (mOrientation == 1) {
							chargeScreenAngle();
						}
						mOrientation = 3;
					} else if (angle == 90) {
						if (mOrientation == 2) {
							chargeScreenAngle();
						}
						mOrientation = 0;
					} else if (angle == 270) {
						if (mOrientation == 0) {
							chargeScreenAngle();
						}
						mOrientation = 2;
					}
				}
			}
		};
		this.mOrientationListener.enable();
	}
}