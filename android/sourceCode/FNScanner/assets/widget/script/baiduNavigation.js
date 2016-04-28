var baiduNavigation = null;
var baiduLocation = null;
apiready = function(){
	    baiduNavigation = api.require('baiduNavigation');
	    baiduLocation =  api.require('baiduLocation');
}

function baiduNavigation1(goalLon,goalLat) {
	baiduLocation.startLocation({
		accuracy: '10m',
		filter: 1,
		autoStop: false
	}, function(ret, err) {
	console.log("fdsfsdfsdfs");
		var sta = ret.status;
		var myLon = ret.longitude;
		var myLat = ret.latitude;
		if (sta) { //定位成功
			console.log("myLon:" + myLon + 'myLat:' + myLat +'goalLon'+goalLon+'goalLat'+goalLat);
			baiduNavigation.start({ ////////开始导航
				start: {
					position: { 
						lon: myLon, 
						lat: myLat 
					}
					// title: "当前位置"
						//address: ""
				},
				end: { // 
					position: { // 
						lon: goalLon, // 
						lat: goalLat // 
					}
					//title: "目标位置", 
					//address: goalAddress 
				}
			}, function(ret, err) {
				if (ret.status) {
					console.log("定位成功");
				} else {
					var msg = "未知错误";
					if (1 == err.code) {
						msg = "获取地理位置失败";
					}
					if (2 == err.code) {
						msg = "定位服务未开启";
					}
					if (3 == err.code) {
						msg = "线路取消";
					}
					if (4 == err.code) {
						msg = "退出导航";
					}
					if (5 == err.code) {
						msg = "退出导航声明页面";
					}
					api.alter({
						title: '导航出错',
						msg: msg
					});
				}
			});
		} else {
			api.alert({
				msg: err.msg
			});
		}
	});
}