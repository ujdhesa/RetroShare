/*
 * RetroShare Android QML App
 * Copyright (C) 2016-2017  Gioacchino Mazzurco <gio@eigenlab.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import org.retroshare.qml_components.LibresapiLocalClient 1.0

Item
{
	id: contactsView
	property string own_gxs_id: ""
	property string own_nick: ""

	Component.onCompleted: refreshOwn()

	function refreshData()
	{
		function refreshCallback(par)
		{
			locationsModel.json = par.response
			if(contactsView.own_gxs_id == "") refreshOwn()
		}
		rsApi.request("/identity/*/", "", refreshCallback)
	}
	function refreshOwn()
	{
		rsApi.request("/identity/own", "", function(par)
		{
			var json = JSON.parse(par.response)
			if(json.data.length > 0)
			{
				contactsView.own_gxs_id = json.data[0].gxs_id
				contactsView.own_nick = json.data[0].name
			}
			else createIdentityDialog.visible = true
		})
	}
	function startChatCallback(par)
	{
		var chId = JSON.parse(par.response).data.chat_id
		stackView.push({
						   item:"qrc:/qml/ChatView.qml",
						   properties: {chatId: chId}
					   })
	}

	onFocusChanged: focus && refreshData()

	JSONListModel
	{
		id: locationsModel
		query: "$.data[*]"
	}

	ListView
	{
		id: locationsListView
		width: parent.width
		height: 300
		model: locationsModel.model
		delegate: Item
		{
			height: 40
			width: parent.width

			MouseArea
			{
				anchors.fill: parent
				onClicked:
				{
					console.log("Contacts view onclicked:", model.name,
								model.gxs_id)
					if(model.own) contactsView.own_gxs_id = model.gxs_id
					else
					{
						var jsonData = { "own_gxs_hex": contactsView.own_gxs_id,
							"remote_gxs_hex": model.gxs_id }
						rsApi.request("/chat/initiate_distant_chat",
									  JSON.stringify(jsonData),
									  contactsView.startChatCallback)
					}
				}
				Rectangle
				{
					id: colorHash
					height: parent.height - 4
					width: height
					anchors.verticalCenter: parent.verticalCenter
					anchors.left: parent.left
					anchors.leftMargin: 2
					color: "white"
					property int childHeight : height/2

					Rectangle
					{
						color: '#' + model.gxs_id.substring(1, 9)
						height: parent.childHeight
						width: height
						anchors.top: parent.top
						anchors.left: parent.left
					}
					Rectangle
					{
						color: '#' + model.gxs_id.substring(9, 17)
						height: parent.childHeight
						width: height
						anchors.top: parent.top
						anchors.right: parent.right
					}
					Rectangle
					{
						color: '#' + model.gxs_id.substring(17, 25)
						height: parent.childHeight
						width: height
						anchors.bottom: parent.bottom
						anchors.left: parent.left
					}
					Rectangle
					{
						color: '#' + model.gxs_id.slice(-8)
						height: parent.childHeight
						width: height
						anchors.bottom: parent.bottom
						anchors.right: parent.right
					}

					MouseArea
					{
						anchors.fill: parent
						onPressAndHold:
						{
							fingerPrintDialog.nick = model.name
							fingerPrintDialog.gxs_id = model.gxs_id
							fingerPrintDialog.visible = true
						}
					}
				}
				Text
				{
					id: nickText
					color: model.own ? "blue" : "black"
					text: model.name
					anchors.left: colorHash.right
					anchors.leftMargin: 5
					anchors.verticalCenter: parent.verticalCenter
				}
			}
		}
	}

	Text
	{
		id: selectedOwnIdentityView
		color: "green"
		anchors.bottom: parent.bottom
		anchors.left: parent.left
		width: parent.width
		text: "Open Chat as: " + contactsView.own_nick + " " + contactsView.own_gxs_id
	}

	Timer
	{
		id: refreshTimer
		interval: 5000
		repeat: true
		onTriggered: if(contactsView.visible) contactsView.refreshData()
		Component.onCompleted: start()
	}


	Dialog
	{
		id: createIdentityDialog
		visible: false
		title: "You need to create a GXS identity to chat!"
		standardButtons: StandardButton.Save

		onAccepted: rsApi.request("/identity/create_identity", JSON.stringify({"name":identityNameTE.text, "pgp_linked": !psdnmCheckBox.checked }))

		TextField
		{
			id: identityNameTE
			width: 300
		}

		Row
		{
			anchors.top: identityNameTE.bottom
			Text { text: "Pseudonymous: " }
			CheckBox { id: psdnmCheckBox; checked: true; enabled: false }
		}
	}

	Dialog
	{
		id: fingerPrintDialog
		visible: false
		property string nick
		property string gxs_id
		title: nick + " fingerprint:"
		standardButtons: StandardButton.NoButton
		Text
		{
			id: fingerPrintText
			anchors.centerIn: parent
			text: "<pre>" +
				  fingerPrintDialog.gxs_id.substring(1, 9) + "<br/>" +
				  fingerPrintDialog.gxs_id.substring(9, 17) + "<br/>" +
				  fingerPrintDialog.gxs_id.substring(17, 25) + "<br/>" +
				  fingerPrintDialog.gxs_id.slice(-8) + "<br/>" +
				  "</pre>"
		}
	}
}
