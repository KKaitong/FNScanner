/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */
package com.uzmap.pkg.uzmodules.uzFNScanner.Zxing;

import java.io.File;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.nio.charset.Charset;
import org.json.JSONException;
import org.json.JSONObject;
import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.os.Handler;
import android.view.Gravity;
import android.view.SurfaceHolder;
import android.view.SurfaceHolder.Callback;
import android.view.SurfaceView;
import android.widget.FrameLayout;
import com.google.zxing.Result;
import com.uzmap.pkg.uzcore.uzmodule.UZModuleContext;
import com.uzmap.pkg.uzmodules.uzFNScanner.UzFNScanner;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.camera.CameraManager;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.decoding.CaptureActivityHandlerView;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.decoding.InactivityTimer;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.view.ViewfinderView;
import com.uzmap.pkg.uzmodules.uzFNScanner.utlis.BeepUtil;
import com.uzmap.pkg.uzmodules.uzFNScanner.utlis.ScanUtil;

public class CaptureView extends FrameLayout implements Callback {
	private Context mContext;
	private UzFNScanner mUzFNScanner;
	private UZModuleContext mModuleContext;
	private SurfaceView mSurfaceView;
	private CaptureActivityHandlerView mHandler;
	private ViewfinderView mViewfinderView;
	private InactivityTimer mInactivityTimer;
	private boolean mHasSurface;
	private String mSavePath;
	private int mSaveW;
	private int mSaveH;
	private boolean mIsSaveToAlbum;
	private BeepUtil mBeepUtil;

	public CaptureView(Context context, UzFNScanner uzFNScanner,
			UZModuleContext moduleContext) {
		super(context);
		this.mUzFNScanner = uzFNScanner;
		this.mContext = context;
		this.mModuleContext = moduleContext;
		init();
		initView();
	}

	public void initParams(String savePath, int saveW, int saveH,
			String beepPath, boolean isSaveToAlbum) {
		mSavePath = savePath;
		mSaveW = saveW;
		mSaveH = saveH;
		mBeepUtil = new BeepUtil(mContext, beepPath);
		this.mIsSaveToAlbum = isSaveToAlbum;
	}

	private void init() {
		CameraManager.init(mContext);
		mSurfaceView = new SurfaceView(mContext);
		mHasSurface = false;
		mInactivityTimer = new InactivityTimer((Activity) mContext);

	}

	private void initView() {
		FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
				FrameLayout.LayoutParams.MATCH_PARENT,
				FrameLayout.LayoutParams.MATCH_PARENT);
		params.gravity = Gravity.CENTER;
		mSurfaceView.setLayoutParams(params);
		addView(mSurfaceView);
	}

	public void onResume() {
		initSurface();
		mBeepUtil.initBeep();
	}

	@SuppressWarnings("deprecation")
	private void initSurface() {
		SurfaceHolder surfaceHolder = mSurfaceView.getHolder();
		if (mHasSurface) {
			initCamera(surfaceHolder);
		} else {
			surfaceHolder.addCallback(this);
			surfaceHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
		}
	}

	public void onPause() {
		if (mHandler != null) {
			mHandler.quitSynchronously();
			mHandler = null;
		}
		CameraManager.get().closeDriver();
	}

	public void onDestroy() {
		mInactivityTimer.shutdown();
	}

	private void initCamera(SurfaceHolder surfaceHolder) {
		try {
			int width = 1920;
			int heigth = 1080;
			CameraManager.get().openDriver(surfaceHolder, width, heigth);
			CameraManager.get().setScreemOrientation(90);
		} catch (IOException ioe) {
			return;
		} catch (RuntimeException e) {
			return;
		}
		if (mHandler == null) {
			mHandler = new CaptureActivityHandlerView(this, null, null);
		}
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
		}

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

	public void drawViewfinder() {

	}

	public void handleDecode(final Result obj, Bitmap barcode) {
		mInactivityTimer.onActivity();
		mBeepUtil.playBeepSoundAndVibrate();
		String savePath = null;
		ScanUtil.scanResult2img(obj.getText(), mSavePath, mSaveW, mSaveH,
				mIsSaveToAlbum, false, mContext);
		if (!isBlank(mSavePath)) {
			savePath = new File(mSavePath).getAbsolutePath();
		}
		dealResult(obj.toString(), savePath, ScanUtil.ALBUM_IMG_PATH);
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

	public void dealResult(String stringExtra, String savePath, String albumPath) {
		try {
			String GB_Str = "";
			boolean ISO = Charset.forName("ISO-8859-1").newEncoder()
					.canEncode(stringExtra);
			if (ISO) {
				GB_Str = new String(stringExtra.getBytes("ISO-8859-1"),
						"GB2312");
				callback(GB_Str, savePath, albumPath);
			} else {
				callback(stringExtra, savePath, albumPath);
			}
		} catch (UnsupportedEncodingException e) {
			e.printStackTrace();
		}
	}

	private void callback(String result, String savePath, String albumPath) {
		JSONObject object = new JSONObject();
		try {
			object.put("imgPath", savePath);
			if (albumPath != null)
				object.put("albumPath", albumPath);
			object.put("content", result);
			object.put("eventType", "success");
			mModuleContext.success(object, false);
			mUzFNScanner.openDIYScanner(mModuleContext);
		} catch (JSONException e) {
			e.printStackTrace();
		}
	}
}