/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */
package com.uzmap.pkg.uzmodules.uzFNScanner.utlis;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.text.TextUtils;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.RGBLuminanceSource;
import com.google.zxing.Result;
import com.google.zxing.common.GlobalHistogramBinarizer;
import com.google.zxing.common.HybridBinarizer;

public class ScannerDecoder {
	
	public static final Map<DecodeHintType, Object> HINTS = new EnumMap<>(DecodeHintType.class);

    static {
        List<BarcodeFormat> allFormats = new ArrayList<>();
        allFormats.add(BarcodeFormat.AZTEC);
        allFormats.add(BarcodeFormat.CODABAR);
        allFormats.add(BarcodeFormat.CODE_39);
        allFormats.add(BarcodeFormat.CODE_93);
        allFormats.add(BarcodeFormat.CODE_128);
        allFormats.add(BarcodeFormat.DATA_MATRIX);
        allFormats.add(BarcodeFormat.EAN_8);
        allFormats.add(BarcodeFormat.EAN_13);
        allFormats.add(BarcodeFormat.ITF);
        allFormats.add(BarcodeFormat.MAXICODE);
        allFormats.add(BarcodeFormat.PDF_417);
        allFormats.add(BarcodeFormat.QR_CODE);
        allFormats.add(BarcodeFormat.RSS_14);
        allFormats.add(BarcodeFormat.RSS_EXPANDED);
        allFormats.add(BarcodeFormat.UPC_A);
        allFormats.add(BarcodeFormat.UPC_E);
        allFormats.add(BarcodeFormat.UPC_EAN_EXTENSION);

        HINTS.put(DecodeHintType.TRY_HARDER, BarcodeFormat.QR_CODE);
        HINTS.put(DecodeHintType.POSSIBLE_FORMATS, allFormats);
        HINTS.put(DecodeHintType.CHARACTER_SET, "utf-8");
    }

	private ScannerDecoder() {
	}

	private static ScannerDecoder decoder;

	public static ScannerDecoder getInstance() {
		if (decoder == null) {
			decoder = new ScannerDecoder();
		}
		return decoder;
	}

	/**
	 * 解析二维码图片
	 * 
	 * @return
	 */
//	public static Result scanningImg(String path, Bitmap bitmap) {
//		if (TextUtils.isEmpty(path)) {
//			return null;
//		}
//		Hashtable<DecodeHintType, Object> hints = new Hashtable<DecodeHintType, Object>();
//
//		Vector<BarcodeFormat> decodeFormats = new Vector<BarcodeFormat>();
//		if (decodeFormats == null || decodeFormats.isEmpty()) {
//			decodeFormats = new Vector<BarcodeFormat>();
//
//			// 这里设置可扫描的类型，我这里选择了都支持
//			decodeFormats.addAll(DecodeFormatManager.ONE_D_FORMATS);
//			decodeFormats.addAll(DecodeFormatManager.QR_CODE_FORMATS);
//			decodeFormats.addAll(DecodeFormatManager.DATA_MATRIX_FORMATS);
//		}
//		hints.put(DecodeHintType.POSSIBLE_FORMATS, decodeFormats);
//		hints.put(DecodeHintType.CHARACTER_SET, "utf-8");
//		BitmapFactory.Options options = new BitmapFactory.Options();
//		options.inJustDecodeBounds = true;
//		bitmap = BitmapFactory.decodeFile(path, options);
//		options.inJustDecodeBounds = false;
//		int sampleSize = (int) (options.outHeight / (float) 200);
//		if (sampleSize <= 0)
//			sampleSize = 1;
//		options.inSampleSize = sampleSize;
//		bitmap = BitmapFactory.decodeFile(path, options);
//		if (bitmap == null) {
//			return null;
//		}
//		RGBLuminanceSource source = new RGBLuminanceSource(bitmap);
//		BinaryBitmap binaryBitmap = new BinaryBitmap(
//				new HybridBinarizer(source));
//		QRCodeReader reader = new QRCodeReader();
//		try {
//			return reader.decode(binaryBitmap, hints);
//		} catch (NotFoundException e) {
//			e.printStackTrace();
//		} catch (ChecksumException e) {
//			e.printStackTrace();
//		} catch (FormatException e) {
//			e.printStackTrace();
//		}
//		return null;
//	}

//	public static Result decodeBar(String path) {
//		MultiFormatReader multiFormatReader = new MultiFormatReader();
//		// 解码的参数
//		Hashtable<DecodeHintType, Object> hints = new Hashtable<DecodeHintType, Object>(
//				2);
//		// 可以解析的编码类型
//		Vector<BarcodeFormat> decodeFormats = new Vector<BarcodeFormat>();
//		if (decodeFormats == null || decodeFormats.isEmpty()) {
//			decodeFormats = new Vector<BarcodeFormat>();
//			// 这里设置可扫描的类型，我这里选择了都支持
////			decodeFormats.addAll(DecodeFormatManager.ONE_D_FORMATS);
////			decodeFormats.addAll(DecodeFormatManager.QR_CODE_FORMATS);
////			decodeFormats.addAll(DecodeFormatManager.DATA_MATRIX_FORMATS);
//			
//			//decodeFormats.addAll(DecodeFormatManager.PRODUCT_FORMATS);
//			
//			decodeFormats.add(BarcodeFormat.AZTEC);
//			decodeFormats.add(BarcodeFormat.CODABAR);
//			decodeFormats.add(BarcodeFormat.CODE_39);
//			decodeFormats.add(BarcodeFormat.CODE_93);
//			decodeFormats.add(BarcodeFormat.CODE_128);
//			decodeFormats.add(BarcodeFormat.DATA_MATRIX);
//			decodeFormats.add(BarcodeFormat.EAN_8);
//			decodeFormats.add(BarcodeFormat.EAN_13);
//			decodeFormats.add(BarcodeFormat.ITF);
//			decodeFormats.add(BarcodeFormat.MAXICODE);
//			decodeFormats.add(BarcodeFormat.PDF_417);
//			decodeFormats.add(BarcodeFormat.QR_CODE);
//			decodeFormats.add(BarcodeFormat.RSS_14);
//			decodeFormats.add(BarcodeFormat.RSS_EXPANDED);
//			decodeFormats.add(BarcodeFormat.UPC_A);
//			decodeFormats.add(BarcodeFormat.UPC_E);
//			decodeFormats.add(BarcodeFormat.UPC_EAN_EXTENSION);
//		}
//		hints.put(DecodeHintType.POSSIBLE_FORMATS, decodeFormats);
//		hints.put(DecodeHintType.TRY_HARDER, BarcodeFormat.QR_CODE);
//
//		// 设置继续的字符编码格式为UTF8
//		hints.put(DecodeHintType.CHARACTER_SET, "UTF8");
//
//		// 设置解析配置参数
//		multiFormatReader.setHints(hints);
//
//		// 开始对图像资源解码
//		Result rawResult = null;
//		try {
//			Bitmap bitmap = getScaledBitmap(path);
//			if (bitmap == null) {
//				return null;
//			}
//			// Bitmap resize = Bitmap.createScaledBitmap(
//			// BitmapFactory.decodeFile(path), 100, 100, false);
//			rawResult = multiFormatReader.decodeWithState(new BinaryBitmap(
//					new HybridBinarizer(new BitmapLuminanceSource(bitmap))));
//		} catch (NotFoundException e) {
//			e.printStackTrace();
//			return null;
//		} catch (Exception e) {
//			return null;
//		}
//		return rawResult;
//	}
	
	public static Result decodeBar(String path) {
		if (TextUtils.isEmpty(path)) {
            return null;  
        }
		
		Bitmap bitmap = getDecodeAbleBitmap(path);
		
        // DecodeHintType 和EncodeHintType  
		Result result = null;
        RGBLuminanceSource source = null;
        try {
            int width = bitmap.getWidth();
            int height = bitmap.getHeight();
            int[] pixels = new int[width * height];
            bitmap.getPixels(pixels, 0, width, 0, 0, width, height);
            source = new RGBLuminanceSource(width, height, pixels);
            result = new MultiFormatReader().decode(new BinaryBitmap(new HybridBinarizer(source)), HINTS);
            return result;
        } catch (Exception e) {
            e.printStackTrace();
            if (source != null) {
                try {
                    result = new MultiFormatReader().decode(new BinaryBitmap(new GlobalHistogramBinarizer(source)), HINTS);
                    return result;
                } catch (Throwable e2) {
                    e2.printStackTrace();
                }
            }
            return null;
        }
	}
	
	private static Bitmap getDecodeAbleBitmap(String picturePath) {
        try {
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(picturePath, options);
            int sampleSize = options.outHeight / 400;
            if (sampleSize <= 0) {
                sampleSize = 1;
            }
            options.inSampleSize = sampleSize;
            options.inJustDecodeBounds = false;

            return BitmapFactory.decodeFile(picturePath, options);
        } catch (Exception e) {
            return null;
        }
    }
	

	private static Bitmap getScaledBitmap(String path) {
		Bitmap bitmap = null;
		BitmapFactory.Options options = new BitmapFactory.Options();
		options.inJustDecodeBounds = true;
		bitmap = BitmapFactory.decodeFile(path, options);
		options.inJustDecodeBounds = false;
		int sampleSize = (int) (options.outHeight / (float) 200);
		if (sampleSize <= 0)
			sampleSize = 1;
		options.inSampleSize = sampleSize;
		bitmap = BitmapFactory.decodeFile(path, options);
		return bitmap;
	}

	/**
	 * 将bitmap由RGB转换为YUV
	 * 
	 * @param bitmap
	 *            转换的图形
	 * @return YUV数据
	 */
	public static byte[] rgb2YUV(Bitmap bitmap) {
		int width = bitmap.getWidth();
		int height = bitmap.getHeight();
		int[] pixels = new int[width * height];
		bitmap.getPixels(pixels, 0, width, 0, 0, width, height);
		int len = width * height;
		byte[] yuv = new byte[len * 3 / 2];
		int y, u, v;
		for (int i = 0; i < height; i++) {
			for (int j = 0; j < width; j++) {
				int rgb = pixels[i * width + j] & 0x00FFFFFF;
				int r = rgb & 0xFF;
				int g = (rgb >> 8) & 0xFF;
				int b = (rgb >> 16) & 0xFF;
				y = ((66 * r + 129 * g + 25 * b + 128) >> 8) + 16;
				u = ((-38 * r - 74 * g + 112 * b + 128) >> 8) + 128;
				v = ((112 * r - 94 * g - 18 * b + 128) >> 8) + 128;
				y = y < 16 ? 16 : (y > 255 ? 255 : y);
				u = u < 0 ? 0 : (u > 255 ? 255 : u);
				v = v < 0 ? 0 : (v > 255 ? 255 : v);
				yuv[i * width + j] = (byte) y;
			}
		}
		return yuv;
	}
}
