/*
 * Copyright (C) 2008 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.view;

import java.util.Collection;
import java.util.HashSet;

import android.app.Activity;
import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.ComposeShader;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.RadialGradient;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.Shader.TileMode;
import android.graphics.SweepGradient;
import android.support.v4.widget.DrawerLayout.DrawerListener;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

import com.apicloud.fnscanner.R;
import com.google.zxing.ResultPoint;
import com.uzmap.pkg.uzcore.UZResourcesIDFinder;
import com.uzmap.pkg.uzkit.UZUtility;
import com.uzmap.pkg.uzmodules.uzFNScanner.UzFNScanner;
import com.uzmap.pkg.uzmodules.uzFNScanner.Zxing.camera.CameraManager;

/**
 * This view is overlaid on top of the camera preview. It adds the viewfinder
 * rectangle and partial transparency outside it, as well as the laser scanner
 * animation and result points.
 * 
 * @author dswitkin@google.com (Daniel Switkin)
 */
public final class ViewfinderView extends View {
	private static final long ANIMATION_DELAY = 10L;
	private Bitmap resultBitmap;
	private Collection<ResultPoint> possibleResultPoints;
	// =========
	private final Paint paint;
	private Collection<ResultPoint> lastPossibleResultPoints;
	private static final int OPAQUE = 0xFF;
	// 扫描点的颜色
	private int resultPointColor = 0xC0FFFF00;
	// 扫描区域边框颜色
	private int frameColor = 0x90FFFFFF;
	// 四角颜色
	private int cornerColor = 0x00FF00;
	private static final int CORNER_RECT_WIDTH = 8; // 扫描区边角的宽
	private static final int CORNER_RECT_HEIGHT = 40; // 扫描区边角的高
	private static final int SCANNER_LINE_MOVE_DISTANCE = 5; // 扫描线移动距离
	private static final int SCANNER_LINE_HEIGHT = 10; // 扫描线宽度
	private int resultColor = 0xB0000000;
	private int maskColor = 0x60000000;
	private Context mContext;

	// 扫描线颜色
	private int laserColor = 0x00FF00;
	public static int scannerStart = 0;
	public static int scannerEnd = 0;
	
	private final String text = "对准条形码／二维码，即可自动扫描";
	private String mOrientationStr;
	

	public ViewfinderView(Context context, AttributeSet attrs) {
		super(context, attrs);
		
		int orientation = context.getResources().getIdentifier("orientation", "attr", context.getPackageName());
		TypedArray ta = context.obtainStyledAttributes(attrs, new int[] {orientation});
		mOrientationStr = ta.getString(UZResourcesIDFinder.getResStyleableID("ViewfinderView_orientation"));
		ta.recycle();
		
		scannerStart = 0;
		scannerEnd = 0;
		paint = new Paint();
		paint.setAntiAlias(true);
		possibleResultPoints = new HashSet<ResultPoint>(5);
		this.mContext = context;
	}

	@Override
	public void onDraw(Canvas canvas) {
		Rect frame;
		if (TextUtils.equals("port", mOrientationStr)) {//竖屏
			frame = CameraManager.get().getFramingRect();
		}else if (TextUtils.equals("land", mOrientationStr)) {//横屏
			frame = CameraManager.get().getLandFramingRect();
		}else {
			frame = CameraManager.get().getFramingRect();
		}
		

		if (frame == null) {
			return;
		}

		if (scannerStart == 0 || scannerEnd == 0) {
			scannerStart = frame.top;
			scannerEnd = frame.bottom;
		}

		int width = canvas.getWidth();
		int height = canvas.getHeight();
		// Draw the exterior (i.e. outside the framing rect) darkened
		drawExterior(canvas, frame, width, height);

		if (resultBitmap != null) {
			paint.setAlpha(OPAQUE);
		    canvas.drawBitmap(resultBitmap, frame.left, frame.top, paint);
		} else {
			// Request another update at the animation interval, but only
			// repaint the laser line,
			// not the entire viewfinder mask.
			drawLine(canvas, frame);
			postInvalidateDelayed(ANIMATION_DELAY, frame.left, frame.top, frame.right, frame.bottom);
		}
	}

	private void drawExterior(Canvas canvas, Rect frame, int width, int height) {
		paint.setColor(resultBitmap != null ? resultColor : maskColor);
		//paint.setColor(Color.parseColor("#f21E2126"));
		canvas.drawRect(0, 0, width, frame.top, paint);//上面的阴影部分
		canvas.drawRect(0, frame.top, frame.left, frame.bottom + 1, paint);//左边
		canvas.drawRect(frame.right + 1, frame.top, width, frame.bottom + 1, paint);//右边
		canvas.drawRect(0, frame.bottom + 1, width, height, paint);//下面
	}

	private void drawLine(Canvas canvas, Rect frame) {

		drawFrame(canvas, frame);

		// 绘制边角 jjj
		drawCorner(canvas, frame);

		// jjj 绘制提示信息
		drawTextInfo(canvas, frame);
				
		// jjj Draw a red "laser scanner" line through the middle to show decoding is
		// active
		drawLaserScanner(canvas, frame);

		Collection<ResultPoint> currentPossible = possibleResultPoints;
		Collection<ResultPoint> currentLast = lastPossibleResultPoints;
		if (currentPossible.isEmpty()) {
			lastPossibleResultPoints = null;
		} else {
			possibleResultPoints = new HashSet<ResultPoint>(5);
			lastPossibleResultPoints = currentPossible;
			paint.setAlpha(OPAQUE);
			paint.setColor(resultPointColor);
			for (ResultPoint point : currentPossible) {
				canvas.drawCircle(frame.left + point.getX(), frame.top + point.getY(), 6.0f, paint);
			}
		}
		if (currentLast != null) {
			paint.setAlpha(OPAQUE / 2);
			paint.setColor(resultPointColor);
			for (ResultPoint point : currentLast) {
				canvas.drawCircle(frame.left + point.getX(), frame.top + point.getY(), 3.0f, paint);
			}
		}
	}

	/**
	 * 画字
	 * @param canvas
	 * @param frame
	 */
	private void drawTextInfo(Canvas canvas, Rect frame) {
		paint.setColor(Color.WHITE);
		paint.setTextSize(sp2px(mContext, 14));
		paint.setTextAlign(Paint.Align.CENTER);
		String hintText = UzFNScanner.mModuleContext.optString("hintText", text);
		canvas.drawText(hintText, frame.left + frame.width() / 2, frame.bottom + CORNER_RECT_HEIGHT + 10, paint);
	}
	
	/**
     * 将sp值转换为px值，保证文字大小不变
     */
    public static int sp2px(Context context, float spValue) {
        final float fontScale = context.getResources().getDisplayMetrics().scaledDensity;
        return (int) (spValue * fontScale + 0.5f);
    }

	private void drawFrame(Canvas canvas, Rect frame) {
		paint.setColor(Color.parseColor("#90FFFFFF"));
		canvas.drawRect(frame.left, frame.top, frame.right + 1, frame.top + 2, paint);
		canvas.drawRect(frame.left, frame.top + 2, frame.left + 2, frame.bottom - 1, paint);
		canvas.drawRect(frame.right - 1, frame.top, frame.right + 1, frame.bottom - 1, paint);
		canvas.drawRect(frame.left, frame.bottom - 1, frame.right + 1, frame.bottom + 1, paint);
	}

	private void drawCorner(Canvas canvas, Rect frame) {
		paint.setColor(Color.WHITE);
		// 左上
		canvas.drawRect(frame.left, frame.top, frame.left + CORNER_RECT_WIDTH, frame.top + CORNER_RECT_HEIGHT, paint);
		canvas.drawRect(frame.left, frame.top, frame.left + CORNER_RECT_HEIGHT, frame.top + CORNER_RECT_WIDTH, paint);
		// 右上
		canvas.drawRect(frame.right - CORNER_RECT_WIDTH, frame.top, frame.right, frame.top + CORNER_RECT_HEIGHT, paint);
		canvas.drawRect(frame.right - CORNER_RECT_HEIGHT, frame.top, frame.right, frame.top + CORNER_RECT_WIDTH, paint);
		// 左下
		canvas.drawRect(frame.left, frame.bottom - CORNER_RECT_WIDTH, frame.left + CORNER_RECT_HEIGHT, frame.bottom,
				paint);
		canvas.drawRect(frame.left, frame.bottom - CORNER_RECT_HEIGHT, frame.left + CORNER_RECT_WIDTH, frame.bottom,
				paint);
		// 右下
		canvas.drawRect(frame.right - CORNER_RECT_WIDTH, frame.bottom - CORNER_RECT_HEIGHT, frame.right, frame.bottom,
				paint);
		canvas.drawRect(frame.right - CORNER_RECT_HEIGHT, frame.bottom - CORNER_RECT_WIDTH, frame.right, frame.bottom,
				paint);
	}

	private void drawLaserScanner(Canvas canvas, Rect frame) {
		paint.setColor(Color.WHITE);
		// 扫描线闪烁效果
		// paint.setAlpha(SCANNER_ALPHA[scannerAlpha]);
		// scannerAlpha = (scannerAlpha + 1) % SCANNER_ALPHA.length;
		// int middle = frame.height() / 2 + frame.top;
		// canvas.drawRect(frame.left + 2, middle - 1, frame.right - 1, middle + 2,
		// paint);
		// 线性渐变
		LinearGradient linearGradient = new LinearGradient(frame.left, scannerStart, frame.left,
				scannerStart + SCANNER_LINE_HEIGHT, shadeColor(laserColor), laserColor, TileMode.MIRROR);

		RadialGradient radialGradient;
		if (TextUtils.isEmpty(mLineColor)) {
			radialGradient = new RadialGradient((float) (frame.left + frame.width() / 2),
					(float) (scannerStart + SCANNER_LINE_HEIGHT / 2), 360f, Color.WHITE, shadeColor(Color.WHITE),
					TileMode.MIRROR);
		}else {
			radialGradient = new RadialGradient((float) (frame.left + frame.width() / 2),
					(float) (scannerStart + SCANNER_LINE_HEIGHT / 2), 360f, UZUtility.parseCssColor(mLineColor), shadeColor(UZUtility.parseCssColor(mLineColor)),
					TileMode.MIRROR);
		}
//		RadialGradient radialGradient = new RadialGradient((float) (frame.left + frame.width() / 2),
//				(float) (scannerStart + SCANNER_LINE_HEIGHT / 2), 360f, Color.WHITE, shadeColor(Color.WHITE),
//				TileMode.MIRROR);

		 SweepGradient sweepGradient = new SweepGradient(
		 (float)(frame.left + frame.width() / 2),
		 (float)(scannerStart + SCANNER_LINE_HEIGHT),
		 shadeColor(laserColor),
		 laserColor);
		
		 ComposeShader composeShader = new ComposeShader(radialGradient,
		 linearGradient, PorterDuff.Mode.ADD);

		paint.setShader(radialGradient);
		if (scannerStart <= scannerEnd) {
			// 矩形
//			canvas.drawRect(frame.left, scannerStart, frame.right, scannerStart +
//			SCANNER_LINE_HEIGHT, paint);
			// 椭圆
			RectF rectF = new RectF(frame.left + 2 * SCANNER_LINE_HEIGHT, scannerStart,
					frame.right - 2 * SCANNER_LINE_HEIGHT, scannerStart + SCANNER_LINE_HEIGHT);
			canvas.drawOval(rectF, paint);
			scannerStart += SCANNER_LINE_MOVE_DISTANCE;
		} else {
			scannerStart = frame.top;
		}
		paint.setShader(null);
	}
	
	private String mLineColor;
	public void setLineColor(String lineColor) {
		this.mLineColor = lineColor;
	}

	// 处理颜色模糊
	public int shadeColor(int color) {
		String hax = Integer.toHexString(color);
		String result = "20" + hax.substring(2);
		return Integer.valueOf(result, 16);
	}

	// ===============================================
	public void drawViewfinder() {
		resultBitmap = null;
		invalidate();
	}

	/**
	 * Draw a bitmap with the result points highlighted instead of the live scanning
	 * display.
	 * 
	 * @param barcode
	 *            An image of the decoded barcode.
	 */
	public void drawResultBitmap(Bitmap barcode) {
		resultBitmap = barcode;
		invalidate();
	}

	public void addPossibleResultPoint(ResultPoint point) {
		possibleResultPoints.add(point);
	}

}
