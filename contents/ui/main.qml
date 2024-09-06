import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.1
import QtQuick.Window 2.15

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: root

    Mpris.Mpris2Model {
        id: mpris2Model
    }

    Mpris.MultiplexerModel {
        id: multiplexerModel
    }

    property string currentMediaTitle: mpris2Model.currentPlayer?.track ?? ""

    property string currentMediaArtists: mpris2Model.currentPlayer?.artist ?? ""

    property string currentMediaAlbum: mpris2Model.currentPlayer?.album ?? ""

    property int playbackStatus: mpris2Model.currentPlayer?.playbackStatus ?? 0

    property bool isPlaying: root.playbackStatus === Mpris.PlaybackStatus.Playing

    property string nameOfCurrentPlayer: mpris2Model.currentPlayer?.objectName ?? ""

    property int position: mpris2Model.currentPlayer?.position ?? 0

    preferredRepresentation: fullRepresentation // Otherwise it will only display your icon declared in the metadata.json file
    Layout.preferredWidth: config_preferedWidgetWidth
    Layout.preferredHeight: lyricText.contentHeight

    width: 0
    height: lyricText.contentHeight

    Text {
        id: lyricText
        text: ""
        color: config_lyricTextColor
        font.pixelSize: config_lyricTextSize
        font.bold: config_lyricTextBold
        font.italic: config_lyricTextItalic
        font.family: config_preferedFont
        anchors.right: parent.right
        anchors.rightMargin: 5.3 * (config_mediaControllItemSize + config_mediaControllSpacing)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: config_lyricTextVerticalOffset
    }

    Item {
        id: iconsContainer
        anchors.right: parent.right
        anchors.rightMargin: 1 //10
        anchors.verticalCenter: parent.verticalCenter
        width: 5 * config_mediaControllItemSize + 4 * config_mediaControllSpacing
        height: config_mediaControllItemSize
        anchors.verticalCenterOffset: config_mediaControllItemVerticalOffset

        Image {
            source: backwardIcon
            sourceSize.width: config_mediaControllItemSize
            sourceSize.height: config_mediaControllItemSize
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    previous();
                }
            }
        }

        Image {
            source: (playbackStatus == 2 && !isWrongPlayer()) ? pauseIcon : playIcon
            sourceSize.width: config_mediaControllItemSize
            sourceSize.height: config_mediaControllItemSize
            anchors.left: parent.left
            anchors.leftMargin: config_mediaControllItemSize + config_mediaControllSpacing
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (playbackStatus == 2) {
                        pause();
                    } else {
                        play();
                    }
                }
            }
        }

        Image {
            source: forwardIcon
            sourceSize.width: config_mediaControllItemSize
            sourceSize.height: config_mediaControllItemSize
            anchors.left: parent.left
            anchors.leftMargin: 2 * (config_mediaControllItemSize + config_mediaControllSpacing)
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    next();
                }
            }
        }

        Image {
            source: liked ? likedIcon : likeIcon
            sourceSize.width: config_mediaControllItemSize
            sourceSize.height: config_mediaControllItemSize
            anchors.left: parent.left
            anchors.leftMargin: 3 * (config_mediaControllItemSize + config_mediaControllSpacing)
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (liked) {
                        liked = false;
                    } else {
                        liked = true;
                    }
                }
            }
        }

        Image {
            id: mediaPlayerIcon
            source: config_yesPlayMusicChecked ? cloudMusicIcon : spotifyIcon
            sourceSize.width: config_mediaControllItemSize
            sourceSize.height: config_mediaControllItemSize
            anchors.left: parent.left
            anchors.leftMargin: 4 * (config_mediaControllItemSize + config_mediaControllSpacing)
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (config_yesPlayMusicChecked) {
                        menuDialog.x = globalPos.x;
                        menuDialog.y = globalPos.y * 3.5;
                        if (!dialogShowed) {
                            menuDialog.show();
                            dialogShowed = true;
                        } else {
                            dialogShowed = false;
                            menuDialog.close();
                        }
                    }
                }
            }
        }
    }

    property bool switchDisplay: false

    property bool dialogShowed: false
    property bool ypmLogined: false
    property string ypmUserName: ""
    property string ypmCookie: ""
    property string csrf_token: ""
    property string neteaseID: ""
    property bool currentMusicLiked: false

    PlasmaCore.Dialog {
        id: menuDialog
        visible: false

        width: column.implicitWidth
        height: column.implicitHeight

        Column {
            spacing: 5

            PlasmaComponents.MenuItem {
                id: userInfoMenuItem
                visible: true
                text: ypmLogined ? ypmUserName : i18n("登录")

                onTriggered: {
                    if (!ypmLogined) {
                        userInfoMenuItem.visible = false;
                        cookieTextField.visible = true;
                    }
                }
            }

            PlasmaComponents.TextField {
                id: cookieTextField
                visible: false
                placeholderText: i18n("Enter your netease id")

                onAccepted: {
                    ypmLogined = true;
                    userInfoMenuItem.visible = true;
                    cookieTextField.visible = false;
                    neteaseID = cookieTextField.text;
                    //need to add a cookie validation in the future
                }
            }

            PlasmaComponents.MenuItem {
                id: ypmCreateDays
                visible: true
                text: ""
            }

            PlasmaComponents.MenuItem {
                id: ypmSongsListened
                visible: true
                text: ""
            }

            PlasmaComponents.MenuItem {
                id: ypmFollowed
                visible: true
                text: ""
            }

            PlasmaComponents.MenuItem {
                id: ypmFollow
                visible: true
                text: "需要登录"
            }

            PlasmaComponents.MenuItem {
                id: logout
                visible: true
                text: "登出" // i18n

                onTriggered: {
                    ypmLogined = false;
                    neteaseID = "";
                    ypmSongsListened.text = ""; //同理，原本是可以三元做的
                    ypmFollowed.text = "";
                    ypmFollow.text = "";
                    ypmCreateDays.text = "";
                }
            }
        }
    }

    Timer {
        id: ypmUserInfoTimer
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            if (ypmLogined) {
                getUserDetail();
            }
        }
    }

    Timer {
        id: positionTimer
        interval: 1
        running: true
        repeat: true
        onTriggered: {
            mpris2Model.currentPlayer.updatePosition();
        }
    }

    Timer {
        id: schedulerTimer
        interval: 1
        running: true
        repeat: true
        onTriggered: {
            // console.log(JSON.stringify(multiplexerModel))
            // console.log(multiplexerModel);
            // console.log(multiplexerModel.toString());
            //log();
            // 如果 mpris 里面， 当前播放器和之前的播放器不一样，就重置。
            if (!currentMediaTitle && !currentMediaArtists) {
                mpris2Model.currentPlayer.Pause();
            }
            if (nameOfPreviousPlayer != nameOfCurrentPlayer) {
                nameOfPreviousPlayer = nameOfCurrentPlayer;
                reset();
            }
            // 如果 设置 里面， 当前播放器和之前设置的播放器不一样，就重置。
            if (prevExpectedPlayerName != currExpectedPlayerName) {
                prevExpectedPlayerName = currExpectedPlayerName;
                mpris2Model.currentPlayer.Pause();
                reset();
            }
            // 前后歌名不一样， 重置。
            if (currentMediaTitle != previousMediaTitle || currentMediaArtists != previousMediaArtists) {
                //console.log("Update current media artist and title");
                reset();
                previousMediaTitle = currentMediaTitle;
                previousMediaArtists = currentMediaArtists;
                if (currExpectedPlayerName === "yesplaymusic") {
                    if (nameOfCurrentPlayer === "yesplaymusic") {
                        lyricText.text = " ";
                        lyricsWTimes.clear();
                        yesPlayMusicTimer.start();
                        ypmUserInfoTimer.start();
                    }
                } else {
                    if (nameOfCurrentPlayer !== "yesplaymusic") {
                        compatibleModeTimer.start();
                    }
                }
            }
        }
    }

    property bool isYPMLyricFound: false

    Timer {
        id: yesPlayMusicTimer
        interval: 200
        running: false
        repeat: true
        onTriggered: {
            compatibleModeTimer.stop();
            if (currentMediaArtists === "" && currentMediaTitle === "") {
                lyricText.text = " ";
                lyricsWTimes.clear();
            } else {
                if (!isYPMLyricFound) {
                    fetchMediaIdYPM();
                }
            }
        }
    }

    function log() {
        console.log("currentMediaArtists: ", currentMediaArtists);
        console.log("previousMediaArtists: ", previousMediaArtists);
        console.log("currentMediaTitle: ", currentMediaTitle);
        console.log("previousMediaTitle: ", previousMediaTitle);
    }

    // compatible mode timer
    Timer {
        id: compatibleModeTimer
        interval: 200
        running: false
        repeat: true
        onTriggered: {
            if ((currentMediaArtists === "" && currentMediaTitle === "") || (currentMediaTitle != previousMediaTitle) || currentMediaArtists != previousMediaArtists) {
                lyricText.text = " ";
                lyricsWTimes.clear();
            } else {
                if (!isCompatibleLRCFound || queryFailed) {
                    fetchLyricsCompatibleMode();
                }
            }
        }
    }

    // List/Map that storing [{timestamp: xxx, lyric: xxx}, {timestamp: xxx, lyric: xxx}, {timestamp: xxx, lyric: xxx}]
    ListModel {
        id: lyricsWTimes
    }

    // todo: cache the current listModel
    ListModel {
        id: cachedlyricsWTimes
    }

    // Global constant
    readonly property string ypm_base_url: "http://localhost:27232"
    readonly property string lrclib_base_url: "https://lrclib.net"

    // ui variables
    property string backwardIcon: config_whiteMediaControlIconsChecked ? "../assets/media-backward-white.svg" : "../assets/media-backward.svg"
    property string pauseIcon: config_whiteMediaControlIconsChecked ? "../assets/media-pause-white.svg" : "../assets/media-pause.svg"
    property string forwardIcon: config_whiteMediaControlIconsChecked ? "../assets/media-forward-white.svg" : "../assets/media-forward.svg"
    property string likeIcon: config_whiteMediaControlIconsChecked ? "../assets/media-like-white.svg" : "../assets/media-like.svg"
    property string likedIcon: "../assets/media-liked.svg"
    property string cloudMusicIcon: config_whiteMediaControlIconsChecked ? "../assets/netease-cloud-music-white.svg" : "../assets/netease-cloud-music.svg"
    property string spotifyIcon: config_whiteMediaControlIconsChecked ? "../assets/spotify-white.svg" : "../assets/spotify.svg"
    property string playIcon: config_whiteMediaControlIconsChecked ? "../assets/media-play-white.svg" : "../assets/media-play.svg"
    property bool liked: false

    // config page variable
    property bool config_yesPlayMusicChecked: Plasmoid.configuration.yesPlayMusicChecked
    property bool config_spotifyChecked: Plasmoid.configuration.spotifyChecked
    property bool config_compatibleModeChecked: Plasmoid.configuration.compatibleModeChecked
    property int config_lyricTextSize: Plasmoid.configuration.lyricTextSize
    property string config_lyricTextColor: Plasmoid.configuration.lyricTextColor
    property bool config_lyricTextBold: Plasmoid.configuration.lyricTextBold
    property bool config_lyricTextItalic: Plasmoid.configuration.lyricTextItalic
    property int config_mediaControllSpacing: Plasmoid.configuration.mediaControllSpacing
    property int config_mediaControllItemSize: Plasmoid.configuration.mediaControllItemSize
    property int config_mediaControllItemVerticalOffset: Plasmoid.configuration.mediaControllItemVerticalOffset
    property int config_lyricTextVerticalOffset: Plasmoid.configuration.lyricTextVerticalOffset
    property int config_whiteMediaControlIconsChecked: Plasmoid.configuration.whiteMediaControlIconsChecked
    property int config_preferedWidgetWidth: Plasmoid.configuration.preferedWidgetWidth
    property int config_preferedTextLength: Plasmoid.configuration.preferedTextLength
    property string config_preferedFont: Plasmoid.configuration.preferedFont

    //Other Media Player's mpris2 data
    property int mprisCurrentPlayingSongTimeMS: {
        if (position == 0) {
            return -1;
        } else {
            return Math.floor(position / 1000000);
        }
    }

    property int compatibleIndex: -3

    property int spotifyIndex: -2

    property int ypmIndex: -1

    property string currentMediaYPMId: ""

    //Use to search the next row of lyric in lyricsWTimes
    property int currentLyricIndex: 0

    property string previousMediaTitle: ""

    property string previousMediaArtists: ""

    property string prevNonEmptyLyric: ""

    property string previousLrcId: ""

    // indicating we need to use the back up fetching strategy
    property bool queryFailed: false

    property bool isCompatibleLRCFound: false

    property string nameOfPreviousPlayer: ""

    property string base64Image: ""

    property string prevExpectedPlayerName: ""

    // 0: ypm   1: spotify 2: compatible
    property string currExpectedPlayerName: {
        if (config_yesPlayMusicChecked) {
            return "yesplaymusic";
        } else if (config_spotifyChecked) {
            return "spotify";
        } else {
            return "compatible";
        }
    }

    // construct the lrclib's request url
    property string lrcQueryUrl: {
        var track = encodeURIComponent(currentMediaTitle);
        var album = encodeURIComponent(currentMediaAlbum);
        var artists = encodeURIComponent(currentMediaArtists);
        if (queryFailed) {
            return lrclib_base_url + "/api/search" + "?track_name=" + track + "&artist_name=" + artists + "&album_name=" + album + "&q=" + track;
        } else {
            return lrclib_base_url + "/api/search" + "?track_name=" + track + "&artist_name=" + artists + "&album_name=" + album;
        }
    }

    property string lrc_not_exists: " "

    function fetchMediaIdYPM() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", ypm_base_url + "/player");
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                if (xhr.responseText) {
                    var response = JSON.parse(xhr.responseText);
                    if (response && response.currentTrack && response.currentTrack.name === currentMediaTitle) {
                        previousMediaTitle = currentMediaTitle;
                        previousMediaArtists = currentMediaArtists;
                        currentMediaYPMId = response.currentTrack.id;
                        //console.log("Successfully fetched YPM music id");
                        fetchSyncLyricYPM();
                    }
                }
            }
        };
        xhr.send();
    }

    function fetchSyncLyricYPM() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", ypm_base_url + "/api/lyric?id=" + currentMediaYPMId);
        xhr.onreadystatechange = function () {
            if (xhr.status === 200) {
                var response = JSON.parse(xhr.responseText);
                //console.log("YPM Network OK");
                if (response && response.lrc && response.lrc.lyric) {
                    lyricsWTimes.clear();
                    //console.log("Successfully fetched YPM lyrics");
                    isYPMLyricFound = true;
                    parseLyric(response.lrc.lyric);
                    //parseAndUpload(response.lrc.lyric);
                }
            }
        };
        xhr.send();
    }

    //[Feature haven't been implemented]
    function parseAndUpload(ypmLrc) {
    }

    function likeMusicYPM() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", ypm_base_url + "/api/like" + "?id=");
    }

    // parse the lyric
    // [["[00:26.64] first row of lyric\n"]], ["[00:29.70] second row of lyric\n]"],etc...]
    function parseLyric(lyrics) {
        //console.log("Start parsing Lyrics");
        var lrcList = lyrics.split("\n");
        for (var i = 0; i < lrcList.length; i++) {
            var lyricPerRowWTime = lrcList[i].split("]");
            if (lyricPerRowWTime.length > 1) {
                var timestamp = parseTime(lyricPerRowWTime[0].replace("[", "").trim());
                var lyricPerRow = lyricPerRowWTime[1].trim();
                lyricsWTimes.append({
                    time: timestamp,
                    lyric: lyricPerRow
                });
            }
        }
        lyricDisplayTimer.start();
    }

    function fetchLyricsCompatibleMode() {
        var xhr = new XMLHttpRequest();
        //console.log("Entered fetchlyrics compatible mode.");
        xhr.open("GET", lrcQueryUrl);
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                //Advertisement
                if ((currentMediaTitle !== "Advertisement") && !isCompatibleLRCFound) {
                    if (!xhr.responseText || xhr.responseText === "[]") {
                        //console.log("[Compatible Mode] Failed to get the lyrics.");
                        queryFailed = true;
                        previousLrcId = Number.MIN_VALUE;
                        lyricsWTimes.clear();
                        lyricText.text = lrc_not_exists;
                    } else {
                        var response = JSON.parse(xhr.responseText);
                        queryFailed = false;
                        if (response && response.length > 0 && previousLrcId !== response[0].id.toString()) {
                            lyricsWTimes.clear();
                            previousMediaTitle = currentMediaTitle;
                            previousMediaArtists = currentMediaArtists;
                            previousLrcId = response[0].id.toString();
                            isCompatibleLRCFound = true;
                            parseLyric(response[0].syncedLyrics);
                        } else {
                            lyricsWTimes.clear();
                            lyricText.text = lrc_not_exists;
                        }
                    }
                }
            }
        };
        xhr.send();
    }

    function parseTime(timeString) {
        var parts = timeString.split(":");
        var minutes = parseInt(parts[0], 10);
        var seconds = parseFloat(parts[1]);
        return minutes * 60 + seconds; // miliseconds
    }

    function previous() {
        if (!isWrongPlayer()) {
            mpris2Model.currentPlayer.Previous();
        }
    }

    function play() {
        if (!isWrongPlayer()) {
            mpris2Model.currentPlayer.Play();
        }
    }

    function pause() {
        if (!isWrongPlayer()) {
            mpris2Model.currentPlayer.Pause();
        }
    }

    function next() {
        if (!isWrongPlayer()) {
            mpris2Model.currentPlayer.Next();
        }
    }

    // [v1.1.3] Fix the problem of current playing media doesn't match the selected mode.
    function isWrongPlayer() {
        if (nameOfCurrentPlayer != currExpectedPlayerName) {
            if (currExpectedPlayerName == "compatible") {
                return false;
            } else {
                return true;
            }
        }
        return false;
    }

    function reset() {
        //console.log("entered")
        compatibleModeTimer.stop();
        yesPlayMusicTimer.stop();
        ypmUserInfoTimer.stop();
        previousMediaTitle = "";
        previousMediaArtists = "";
        lyricsWTimes.clear();
        prevNonEmptyLyric = "";
        previousLrcId = "";
        queryFailed = false;
        lyricText.text = " ";
        isCompatibleLRCFound = false;
        isYPMLyricFound = false;
    }

    function getUserDetail() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", ypm_base_url + "/api/user/detail?uid=" + neteaseID);
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                if (xhr.responseText && xhr.responseText !== "[]") {
                    var response = JSON.parse(xhr.responseText);
                    ypmUserName = "你好， " + response.profile.nickname;
                    ypmCreateDays.text = "您已加入云村: " + response.createDays + "天";
                    ypmSongsListened.text = "总计听歌:" + response.listenSongs + "首";
                    ypmFollowed.text = "粉丝: " + response.profile.followeds;
                    ypmFollow.text = "关注: " + response.profile.follows;
                }
            }
        };
        xhr.send();
    }

    function truncateString(inputString) {
        if (inputString.length > config_preferedTextLength) {
            return inputString.substring(0, config_preferedTextLength) + "...";
        }
        return inputString;
    }

    Timer {
        id: lyricDisplayTimer
        interval: 1
        running: false
        repeat: true
        onTriggered: {
            if (currentMediaTitle === "Advertisement") {
                lyricText.text = truncateString(currentMediaTitle);
            } else {
                for (let i = 0; i < lyricsWTimes.count; i++) {
                    if (lyricsWTimes.get(i).time >= mprisCurrentPlayingSongTimeMS) {
                        currentLyricIndex = i > 0 ? i - 1 : 0;
                        var currentLWT = lyricsWTimes.get(currentLyricIndex);
                        var currentLyric = currentLWT.lyric;
                        if (!currentLWT || !currentLyric || currentLyric === "" && prevNonEmptyLyric != "") {
                            lyricText.text = truncateString(prevNonEmptyLyric);
                        } else {
                            lyricText.text = truncateString(currentLyric);
                            prevNonEmptyLyric = currentLyric;
                        }
                        break;
                    }
                }
            }
        }
    }
}
