import QtQuick 2.0
import QtWebKit 3.0
import QtWebKit.experimental 1.0
import "script.js" as Tab 

Item {
    width: 960 
    height: 640 

    // FIXME: handle first tab / webview case 
    property string currentTab: ""
    property bool noTabLeft: (tabModel.count === 0)

    FontLoader { id: fontAwesome; source: "http://netdna.bootstrapcdn.com/font-awesome/3.0/font/fontawesome-webfont.ttf" }

    function openNewTab(pageid, url) {
        console.log("openNewTab: "+ pageid);
        //console.log(tabListView.model.get(tabListView.currentIndex).title);

        if (noTabLeft) {      
            tabModel.set(0, { "title": "Loading..", "url": url, "pageid": pageid, "favicon": "icon/favicon.png" } );
        } else {
            tabModel.append( { "title": "Loading..", "url": url, "pageid": pageid, "favicon": "icon/favicon.png" } );
            // hide current tab and display the new
            Tab.itemMap[currentTab].visible = false;
        }

        var webView = tabView.createObject(container, { id: pageid, objectName: pageid } );
        webView.url = url; // FIXME: should use loadUrl() wrapper 

        Tab.itemMap[pageid] = webView;
        currentTab = pageid;
        tabListView.currentIndex = tabModel.count - 1; // move hightlight down
    }

    function switchToTab(pageid) {
        console.log("switchToTab: "+ pageid + ", currentTab: " + currentTab);
        if (currentTab !== pageid ) { 
            Tab.itemMap[currentTab].visible = false;
            currentTab = pageid;
        }
        Tab.itemMap[currentTab].visible = true;
        // assign url to text bar
        urlText.text = Tab.itemMap[currentTab].url;
    }

    function closeTab(deleteIndex, pageid) { 
        console.log('remove: ' + tabModel.get(deleteIndex))
        // FIXME: TypeError of undefined 
        Tab.itemMap[pageid].visible = false; 
        tabModel.remove(deleteIndex);
        Tab.itemMap[pageid].destroy(); 
        delete(Tab.itemMap[pageid])
        if (noTabLeft) { 
            urlText.text = "";
        } else { 
            // TODO: switch to previous tab? 
            currentTab = tabListView.model.get( tabListView.currentIndex ).pageid
            switchToTab( currentTab ); 
        }
    } 

    function fixUrl(url) {
        // FIXME: get rid of space 
        if (url == "") return url;
        if (url[0] == "/") { return "file://"+url; }
        //FIXME: search engine support here
        if (url.indexOf(":")<0) { return "http://"+url; }
        else { return url;}
    }

    Component {
        id: tabView
        WebView { 
            anchors.left: parent.left 
            anchors.top: parent.top
            anchors.fill: parent

            z: 2 // for drawer open/close control  
            anchors.topMargin: 40 // FIXME: should use navigator bar item
            experimental.userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"
            onLoadingChanged: { 
                urlText.text = Tab.itemMap[currentTab].url;
                if (loadRequest.status == WebView.LoadSucceededStatus) {
                }
            }
        }
    }

    Rectangle {
        id: drawer
        anchors.left: parent.left
        anchors.top: parent.top
        width: Tab.DrawerWidth
        height: parent.height
        color: "#33343E" 

        ListModel { id: tabModel }

        Component {
            id: tabDelegate
            Row {
                spacing: 10
                Rectangle {
                    width: Tab.DrawerWidth
                    height: Tab.DrawerHeight
                    color: "transparent"
                    Image { 
                        height: 16; width: 16; 
                        source: (typeof(Tab.itemMap[model.pageid]) !== "undefined" && Tab.itemMap[model.pageid].icon !== "") ?
                        Tab.itemMap[model.pageid].icon : "icon/favicon.png"; 
                        anchors { top: parent.top; left: parent.left; margins: Tab.DrawerMargin; } 
                    }
                    Text { 
                        text: (typeof(Tab.itemMap[model.pageid]) !== "undefined" && Tab.itemMap[model.pageid].title !== "") ? 
                        Tab.itemMap[model.pageid].title : "Loading..";
                        color: "white"; 
                        anchors { top: parent.top; left: parent.left; margins: Tab.DrawerMargin; leftMargin: Tab.DrawerMargin+30 } 
                    }
                    MouseArea { 
                        anchors.fill: parent; 
                        anchors.rightMargin: 20
                        onClicked: { 
                            tabListView.currentIndex = index;
                            switchToTab(model.pageid);
                        }
                    }

                    Text { 
                        visible: tabListView.currentIndex === index
                        anchors { top: parent.top; right: parent.right; margins: Tab.DrawerMargin }
                        text: "\uF057"
                        font.family: fontAwesome.name
                        font.pointSize: 16
                        color: "gray"
                        MouseArea { 
                            anchors.fill: parent; 
                            onClicked: closeTab(model.index, model.pageid)
                        }
                    }
                }
            }
        }
        ListView {
            id: tabListView
            anchors.fill: parent

            // new tab button 
            header: Rectangle { 
                width: Tab.DrawerWidth
                height: Tab.DrawerHeight
                color: "transparent"
                Text { 
                    text: "\uF067"; font.family: fontAwesome.name; color: "white"; 
                    anchors { top: parent.top; left: parent.left; margins: Tab.DrawerMargin+2; leftMargin: Tab.DrawerMargin+10 }
                }
                Text { 
                    text: "New Tab"
                    color: "white"
                    anchors { top: parent.top; left: parent.left; margins: Tab.DrawerMargin; leftMargin: Tab.DrawerMargin+30 }
                }
                MouseArea { 
                    anchors.fill: parent;
                    onClicked: {
                        openNewTab("page"+tabModel.count, "http://google.com"); 
                    }
                }
            }

            model: tabModel
            delegate: tabDelegate 
            highlight: 

            Rectangle { 
                width: Tab.DrawerWidth; height: Tab.DrawerHeight 
                gradient: Gradient {
                    GradientStop { position: 0.1; color: "#1F1F23" }
                    GradientStop { position: 0.5; color: "#28282F" }
                    GradientStop { position: 0.8; color: "#2A2B31" }
                    GradientStop { position: 1.0; color: "#25252A" }

                }
            }
            highlightFollowsCurrentItem: true 
        }
    }

    Rectangle {
        id: container 
        anchors.left: parent.left 
        anchors.top: parent.top
        width: parent.width
        height: parent.height
        //color: "#E4E4E8" // light gray
        z: 1 
        radius: 3 

        Rectangle { 
            height: 40; width: parent.width; anchors.top: parent.top; anchors.left: parent.left
            radius: 3 
            gradient: Gradient { 
                GradientStop { position: 0.0; color: "#f8f8f8" } // "#FAFAFA" }
                //GradientStop { position: 0.5; color: "#E8E9EC" }
                GradientStop { position: 1.0; color: "#eaeaea" } // "#E2E3E7" }
            }
        }
        // Navigator Bar, should use verticalCenter: parent.verticalCenter
        // drawer button 
        Item { 
            id: drawerButton
            width: 30; height: 30; anchors { top: parent.top; left: parent.left; margins: Tab.DrawerMargin; topMargin: 5 } 
            Text { 
                text: (fontAwesome.status === FontLoader.Ready) ? "\uF0C9" : ""; 
                font.family: fontAwesome.name
                font.pointSize: 28 
                color: "gray"
            }
            MouseArea {
                anchors.fill: parent;
                onClicked: { container.state == "closed" ? container.state = "opened" : container.state = "closed"; }
            }
        }

        // TODO: back / forward button 

        Rectangle { 
            id: urlBar 
            anchors { left: drawerButton.right; top: parent.top; margins: 6 } 
            color: "white"
            height: 25 
            border { width: 1; color: "black" }
            radius: 5 
            width: parent.width - 60

            Rectangle {
                anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                radius: 3

                width: (typeof(Tab.itemMap[currentTab]) !== "undefined") ? 
                parent.width / 100 * Math.max(5, Tab.itemMap[currentTab].loadProgress) : 0 
                color: "#FED164" // light yellow 
                opacity: 0.4
                visible: (typeof(Tab.itemMap[currentTab]) !== "undefined") ? Tab.itemMap[currentTab].loading : false 
            }

            TextInput { 
                id: urlText
                text: (typeof(Tab.itemMap[currentTab]) !== "undefined") ? Tab.itemMap[currentTab].url : ""
                anchors { fill: parent; margins: 5 }
                Keys.onReturnPressed: { 
                    if (!noTabLeft) { 
                        Tab.itemMap[currentTab].url = fixUrl(text) 
                    } else { 
                        openNewTab("page"+tabModel.count, fixUrl(text));
                    }
                    Tab.itemMap[currentTab].focus = true;
                }
                onActiveFocusChanged: { 
                    // FIXME: use State to change property  
                    if (urlText.activeFocus) { urlText.selectAll(); parent.border.color = "#2E6FFD"; parent.border.width = 2;} 
                    else { parent.border.color = "black"; parent.border.width = 1; } 
                }
            }            

            Text {
                id: stopButton
                anchors { right: urlBar.right; rightMargin: 5; verticalCenter: parent.verticalCenter}
                text: "\uF00D"
                font { family: fontAwesome.name; pointSize: 20 }
                color: "gray"
                visible: ( typeof(Tab.itemMap[currentTab]) !== "undefined" && Tab.itemMap[currentTab].loadProgress < 100 && !urlText.focus) ? 
                true : false
                MouseArea {
                    anchors { fill: parent; margins: -10; }
                    onClicked: { Tab.itemMap[currentTab].stop(); }
                }
            }
            Text {
                id: reloadButton
                anchors { right: urlBar.right; rightMargin: 5; verticalCenter: parent.verticalCenter}
                text: "\uF021"
                font { family: fontAwesome.name; pointSize: 20 }
                color: "gray"
                visible: ( typeof(Tab.itemMap[currentTab]) !== "undefined" && Tab.itemMap[currentTab].loadProgress == 100 && !urlText.focus ) ? 
                true : false 
                MouseArea {
                    anchors { fill: parent; margins: -10; }
                    onClicked: { Tab.itemMap[currentTab].reload(); }
                }
            }
            Text {
                id: clearButton
                anchors { right: urlBar.right; rightMargin: 5; verticalCenter: parent.verticalCenter}
                text: "\uF057"
                font { family: fontAwesome.name; pointSize: 20 }
                color: "gray"
                visible: urlText.focus
                MouseArea {
                    anchors { fill: parent; margins: -10; }
                    onClicked: { urlText.text = ""; }
                }
            }
        }

        MouseArea { 
            z: (container.state == "opened") ? 3 : 1
            anchors.fill: parent
            anchors.topMargin: 40 
            onClicked: { container.state == "closed" ? container.state = "opened" : container.state = "closed"; }
        }
        states: [
            State{
                name: "opened"
                PropertyChanges { target: container; anchors.leftMargin: Tab.DrawerWidth }
            },
            State {
                name: "closed"
                PropertyChanges { target: container; anchors.leftMargin: 0 }
            }
        ]
        transitions: [
            Transition {
                to: "*"
                NumberAnimation { target: container; properties: "anchors.leftMargin"; duration: 300; easing.type: Easing.InOutQuad; }
            }
        ]
    }
}