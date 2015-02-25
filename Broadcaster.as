

import flash.media.Camera;
import flash.media.Microphone;
import flash.events.Event;

// prevent sleep and lock
NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;

var nc:NetConnection;
var ns:NetStream;

var cam:Camera = Camera.getCamera();
cam.setMode(video.width, video.height, 10);
video.attachCamera(cam);

var mic:Microphone;

var format:TextFormat = new TextFormat();
format.size = 14;
format.bold = true;

btnConnect.addEventListener(MouseEvent.CLICK, connect);
btnConnect.setStyle("textFormat", format);

btnPublish.addEventListener(MouseEvent.CLICK, publish);
btnPublish.setStyle("textFormat", format);

// open their browser to red5 page
//r5logo.addEventListener(MouseEvent.CLICK, goThere);

var publishing:Boolean = false;

//
message.htmlText = '<b>Broadcaster</b><br/>By Paul Gregoire<br/>http://gregoire.org/<br/>';

// get settings
var so:SharedObject = SharedObject.getLocal("userData");
url.text = so.data.url == null ? "rtmp://192.168.1.2/live" : so.data.url;
streamName.text = so.data.streamName == null ? "livestream" : so.data.streamName;
videoWidth.text = so.data.width == null ? "320" : so.data.width;
videoHeight.text = so.data.height == null ? "240" : so.data.height;
fps.text = so.data.fps == null ? "12" : so.data.fps;
quality.text = so.data.quality == null ? "80" : so.data.quality;
sampleRate.text = so.data.sampleRate == null ? "11" : so.data.sampleRate;
gain.text = so.data.gain == null ? "80" : so.data.gain;

function log(msg:String):void {
	message.text += msg + '\n';
}

function connect(evt:Event):void {
	if (btnConnect.label === 'Connect') {
		log('Connecting...');
		//  create the netConnection
		nc = new NetConnection();
		nc.objectEncoding = ObjectEncoding.AMF0;
		//  set it's client/focus to this
		nc.client = this;
		nc.proxyType = "best";
		// add listeners for netstatus and security issues
		nc.addEventListener(NetStatusEvent.NET_STATUS, onStatus);
		//nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		//nc.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		//nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
		nc.connect(url.text, null);
	} else if (btnConnect.label === 'Disconnect') {
		log('Disconnecting...');
		if (nc.connected) {
			nc.close();
		}
	}       
}
	
function publish(evt:Event):void {
	if (!publishing) {
		btnPublish.label = "Unpublish";
		publishing = true;
		mic = Microphone.getMicrophone();		
		if (mic != null) {
			log("Microphone: " + mic.name);
			mic.rate = int(sampleRate.text);
			mic.gain = Number(gain.text);
			mic.setSilenceLevel(5);
			mic.setLoopBack(false);
			mic.setUseEchoSuppression(true);
			//mic.addEventListener(ActivityEvent.ACTIVITY, activityHandler);
			//mic.addEventListener(StatusEvent.STATUS, statusHandler);
			ns.attachAudio(mic);		
		}
		if (cam != null) {		
			log("Camera: " + cam.name);
			cam.setMode(int(videoWidth.text), int(videoHeight.text), Number(fps.text));
			cam.setQuality(0, int(quality.text));
			ns.attachCamera(cam);
			video.attachCamera(cam);
		}
		if (mic != null || cam != null) {
			ns.publish(streamName.text, "live");
		}
		// save current settings
		var so:SharedObject = SharedObject.getLocal("userData");
		so.data.url = url.text;
		so.data.streamName = streamName.text;
		so.data.width = videoWidth.text;
		so.data.height = videoHeight.text;
		so.data.fps = fps.text;
		so.data.quality = quality.text;
		so.data.sampleRate = sampleRate.text;
		so.data.gain = gain.text;
		so.flush();
	} else {
		btnPublish.label = "Publish";
		publishing = false;
		ns.attachCamera(null);
		ns.attachAudio(null);
		//ns.close();		
	}
}

function onBWDone():void {
	// have to have this for an RTMP connection
	log('onBWDone');
}

function onBWCheck(... rest):uint {
	log('onBWCheck');
	//have to return something, so returning anything :)
	return 0;
}		

function onStatus(evt:NetStatusEvent):void {
	log("NetConnection.onStatus " + evt);
	//traceObject(evt);
	var desc:String;
	if (evt.info !== '' || evt.info !== null) { 
		log("Code: " + evt.info.code);
		switch (evt.info.code) {
			case "NetConnection.Connect.Success": 
				btnConnect.label = "Disconnect";
				ns = new NetStream(nc);
				ns.addEventListener(NetStatusEvent.NET_STATUS, onStatus);
				//ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
				ns.client = this;    
				//
				btnPublish.enabled = true;
				btnPublish.label = "Publish";
				publishing = false;
				break;
			case "NetConnection.Connect.Failed":
				break;
			case "NetConnection.Connect.Rejected":
				desc = evt.info.description;
				log("Description: " + desc);
				break;
			case "NetConnection.Connect.Closed":                    
				btnConnect.label = 'Connect';    
				btnPublish.enabled = false;
				break;
			case "NetConnection.Connect.SSLHandshakeFailed":
				log("SSL handshake failed");
				desc = evt.info.description;
				log("Description: " + desc);
				break;
		}           
	}
}

function goThere(e:MouseEvent){
	var request:URLRequest = new URLRequest("https://github.com/Red5");
	try {
		navigateToURL(request, "_blank");
	} catch (e:Error) {
		log("Error opening url " + e.message);
	}
}

stage.addEventListener(Event.DEACTIVATE, deactivateHandler);
function deactivateHandler(event:Event):void {
    NativeApplication.nativeApplication.exit();
}
