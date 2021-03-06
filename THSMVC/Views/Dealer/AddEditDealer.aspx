﻿<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage<THSMVC.Models.DealerModel>" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
	<title></title>
	<link href="../../Scripts/ExcelPlugin/jquery.handsontable.full.css" rel="stylesheet"
		type="text/css" />
	<style type="text/css">
		.tmpAddMob {
			cursor: pointer;
		}

		.tmpRemMob {
			cursor: pointer;
		}
	</style>
	<script src="../../Scripts/ExcelPlugin/jquery.handsontable.full.js" type="text/javascript"></script>
	<script type="text/javascript">
		addmob = 1;
		addmail = 1;
		$(document).ready(function () {
			if ($("#hdnMob2").val() != '') {
				$("#divMob2").show();
				addmob = 2;
			}
			if ($("#hdnMob3").val() != '') {
				$("#divMob3").show();
				addmob = 3;
			}
			if ($("#hdnMob4").val() != '') {
				$("#divMob4").show();
				addmob = 4;
			}
			if ($("#hdnMob5").val() != '') {
				$("#divMob5").show();
				addmob = 5;
			}
			if ($("#hdnMob6").val() != '') {
				$("#divMob6").show();
				addmob = 6;
			}
			if ($("#hdnMob7").val() != '') {
				$("#divMob7").show();
				addmob = 7;
			}
			if ($("#hdnMob8").val() != '') {
				$("#divMob8").show();
				addmob = 8;
			}
			if ($("#hdnMob9").val() != '') {
				$("#divMob9").show();
				addmob = 9;
			}
			if ($("#hdnMob10").val() != '') {
				$("#divMob10").show();
				addmob = 10;
			}


			if ($("#hdnMail2").val() != '') {
				$("#divMail2").show();
				addmail = 2;
			}
			if ($("#hdnMail3").val() != '') {
				$("#divMail3").show();
				addmail = 3;
			}
			if ($("#hdnMail4").val() != '') {
				$("#divMail4").show();
				addmail = 4;
			}
			if ($("#hdnMail5").val() != '') {
				$("#divMail5").show();
				addmail = 5;
			}
			if ($("#hdnMail6").val() != '') {
				$("#divMail6").show();
				addmail = 6;
			}
			if ($("#hdnMail7").val() != '') {
				$("#divMail7").show();
				addmail = 7;
			}
			if ($("#hdnMail8").val() != '') {
				$("#divMail8").show();
				addmail = 8;
			}
			if ($("#hdnMail9").val() != '') {
				$("#divMail9").show();
				addmail = 9;
			}
			if ($("#hdnMail10").val() != '') {
				$("#divMail10").show();
				addmail = 10;
			}

			$.ajax({
				type: "POST",
				url: "Dealer/DealerBankDetails",
				data: { Id: $("#hdnID").val() },
				dataType: "json",
				async: false,
				beforeSend: function () {
					$.blockUI();   //this is great plugin - 'blockUI'
				},
				success: function (result) {
					if (result.success) {
						data = result.data;
						ColHeaders = result.colheaders;
						hdata = result.hdata;
						hColHeaders = result.hcolheaders;
						var MaxCols = '6';
						debugger;
						$('#divDealerBankDetails').handsontable({
							data: data,
							minRows: 0,
							minCols: parseInt(MaxCols, 0),
							minSpareRows: 0,
							colHeaders: ColHeaders,
							autoWrapRow: true,
							contextMenu: false,
							fixedColumnsLeft: 1,
							width: $("#Content").innerWidth(),
							cells: function (row, col, prop) {
								var cellProperties = {};
								if (col === 0) {
									if ($("#hdnID").val() != 0) {
										cellProperties.readOnly = true;
										cellProperties.renderer = ReadOnlyRenderer;
									}
								}

								return cellProperties;
							}
						});
						var hot = $('#divDealerBankDetails').handsontable('getInstance');
						hot.updateSettings({
							colHeaders: hColHeaders,
							columns: hdata
						});
					}
					else {
						alert('error');
					}
					$.unblockUI();
				},
				error: function (XMLHttpRequest, textStatus, errorThrown) {
					debugger;
					Error(XMLHttpRequest, textStatus, errorThrown);
				}
			});
		});
		function ReadOnlyRenderer(instance, td, row, col, prop, value, cellProperties) {
			Handsontable.TextCell.renderer.apply(this, arguments);
			$(td).css({
				background: '#BCDFF5', color: '#000'
			});
		};
		$(document).ready(function () {
			//	$("#DealerName").focus();
			$('#divDealerBankDetails').focus();

			$("#PinCode").keydown(function (event) {
				if ((event.keyCode >= 48 && event.keyCode <= 57) || (event.keyCode >= 96 && event.keyCode <= 105) || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 46 || event.keyCode == 190) {

				} else {
					event.preventDefault();
				}
			});
			$("#MobileNUmber1").keydown(function (event) {
				if ((event.keyCode >= 48 && event.keyCode <= 57) || (event.keyCode >= 96 && event.keyCode <= 105) || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 46 || event.keyCode == 190) {

				} else {
					event.preventDefault();
				}
			});
			$("#MobileNUmber2").keydown(function (event) {
				if ((event.keyCode >= 48 && event.keyCode <= 57) || (event.keyCode >= 96 && event.keyCode <= 105) || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 46 || event.keyCode == 190) {

				} else {
					event.preventDefault();
				}
			});
			$("#MobileNUmber3").keydown(function (event) {
				if ((event.keyCode >= 48 && event.keyCode <= 57) || (event.keyCode >= 96 && event.keyCode <= 105) || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 46 || event.keyCode == 190) {

				} else {
					event.preventDefault();
				}
			});
			$("#MobileNUmber4").keydown(function (event) {
				if ((event.keyCode >= 48 && event.keyCode <= 57) || (event.keyCode >= 96 && event.keyCode <= 105) || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 46 || event.keyCode == 190) {

				} else {
					event.preventDefault();
				}
			});
			$("#MobileNUmber5").keydown(function (event) {
				if ((event.keyCode >= 48 && event.keyCode <= 57) || (event.keyCode >= 96 && event.keyCode <= 105) || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 46 || event.keyCode == 190) {

				} else {
					event.preventDefault();
				}
			});
			$("#MobileNUmber6").keydown(function (event) {
				if ((event.keyCode >= 48 && event.keyCode <= 57) || (event.keyCode >= 96 && event.keyCode <= 105) || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 46 || event.keyCode == 190) {

				} else {
					event.preventDefault();
				}
			});
			$("#MobileNUmber7").keydown(function (event) {
				if ((event.keyCode >= 48 && event.keyCode <= 57) || (event.keyCode >= 96 && event.keyCode <= 105) || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 46 || event.keyCode == 190) {

				} else {
					event.preventDefault();
				}
			});
			$("#MobileNUmber8").keydown(function (event) {
				if ((event.keyCode >= 48 && event.keyCode <= 57) || (event.keyCode >= 96 && event.keyCode <= 105) || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 46 || event.keyCode == 190) {

				} else {
					event.preventDefault();
				}
			});
			$("#MobileNUmber9").keydown(function (event) {
				if ((event.keyCode >= 48 && event.keyCode <= 57) || (event.keyCode >= 96 && event.keyCode <= 105) || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 46 || event.keyCode == 190) {

				} else {
					event.preventDefault();
				}
			});
			$("#MobileNUmber10").keydown(function (event) {
				if ((event.keyCode >= 48 && event.keyCode <= 57) || (event.keyCode >= 96 && event.keyCode <= 105) || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 46 || event.keyCode == 190) {

				} else {
					event.preventDefault();
				}
			});
		});
		function Back() {
			ClearMsg();
			$("#divDealerMaster").show();
			$("#CreateDealer").show();
			$("#backToList").hide();
			$("#divCreateDealer").hide();
			$("#list").trigger("reloadGrid");
		}
		function AddMob(obj) {
			if (addmob < 10) {
				var nextid = parseInt(addmob) + 1;
				$("#divMob" + nextid).show();
				addmob = nextid;
			}
		}
		function RemMob(obj) {
			if (addmob > 1) {
				var previd = parseInt(addmob);
				$("#divMob" + previd).hide();
				$("#MobileNUmber" + previd).val('');
				$("#MobileNUmber" + previd + "Com").val('');
				addmob = previd - 1;
			}
			else
				return false;
		}
		function AddMail(obj) {
			if (addmail < 10) {
				var nextid = parseInt(addmail) + 1;
				$("#divMail" + nextid).show();
				addmail = nextid;
			}
		}
		function RemMail(obj) {
			if (addmail > 1) {
				var previd = parseInt(addmail);
				$("#divMail" + previd).hide();
				$("#Email" + previd).val('');
				$("#Email" + previd + "Com").val('');
				addmail = previd - 1;
			}
			else
				return false;
		}
		function submitDealer() {
			ClearMsg();
			var msg = '';
			if ($("#DealerName").val() == '') {
				msg = 'Please enter Dealer Name<br/>';
			}
			if ($("#CompanyName").val() == '') {
				msg += 'Please enter Company Name<br/>';
			}
			if (msg != "") {
				Failure(msg);
				return;
			}
			$.ajax({
				type: "POST",
				url: "/Dealer/SubmitDealer",
				data: {
					Id: $("#hdnID").val(),
					DealerName: $("#DealerName").val(),
					CompanyName: $("#CompanyName").val(),
					CompanyShortForm: $("#CompanyShortForm").val(),
					Address: $("#Address").val(),
					City: $("#City").val(),
					State: $("#State").val(),
					PinCode: $("#PinCode").val(),
					TinNo: $("#TinNo").val(),
					MobileNUmber1: $("#MobileNUmber1").val(),
					MobileNUmber2: $("#MobileNUmber2").val(),
					MobileNUmber3: $("#MobileNUmber3").val(),
					MobileNUmber4: $("#MobileNUmber4").val(),
					MobileNUmber5: $("#MobileNUmber5").val(),
					MobileNUmber6: $("#MobileNUmber6").val(),
					MobileNUmber7: $("#MobileNUmber7").val(),
					MobileNUmber8: $("#MobileNUmber8").val(),
					MobileNUmber9: $("#MobileNUmber9").val(),
					MobileNUmber10: $("#MobileNUmber10").val(),
					MobileNUmber1Com: $("#MobileNUmber1Com").val(),
					MobileNUmber2Com: $("#MobileNUmber2Com").val(),
					MobileNUmber3Com: $("#MobileNUmber3Com").val(),
					MobileNUmber4Com: $("#MobileNUmber4Com").val(),
					MobileNUmber5Com: $("#MobileNUmber5Com").val(),
					MobileNUmber6Com: $("#MobileNUmber6Com").val(),
					MobileNUmber7Com: $("#MobileNUmber7Com").val(),
					MobileNUmber8Com: $("#MobileNUmber8Com").val(),
					MobileNUmber9Com: $("#MobileNUmber9Com").val(),
					MobileNUmber10Com: $("#MobileNUmber10Com").val(),
					Email1: $("#Email1").val(),
					Email2: $("#Email2").val(),
					Email3: $("#Email3").val(),
					Email4: $("#Email4").val(),
					Email5: $("#Email5").val(),
					Email6: $("#Email6").val(),
					Email7: $("#Email7").val(),
					Email8: $("#Email8").val(),
					Email9: $("#Email9").val(),
					Email10: $("#Email10").val(),
					Email1Com: $("#Email1Com").val(),
					Email2Com: $("#Email2Com").val(),
					Email3Com: $("#Email3Com").val(),
					Email4Com: $("#Email4Com").val(),
					Email5Com: $("#Email5Com").val(),
					Email6Com: $("#Email6Com").val(),
					Email7Com: $("#Email7Com").val(),
					Email8Com: $("#Email8Com").val(),
					Email9Com: $("#Email9Com").val(),
					Email10Com: $("#Email10Com").val(),
					BankData: JSON.stringify($("#divDealerBankDetails").handsontable('getData'))
				},
				dataType: "json",
				beforeSend: function () {
					$.blockUI();
				},
				success: function (response) {
					if (response.success) {
						Success(response.message);
						setTimeout("Back();", 1000);
					}
					else
						Failure(response.message);
					$.unblockUI();
				},
				error: function (XMLHttpRequest, textStatus, errorThrown) {
					$.unblockUI();
					Error(XMLHttpRequest, textStatus, errorThrown);
				}
			});
		}
	</script>
</head>
<body>
	<div class="clear">
		<div id="AddEditDealer">
			<div class="clear">
				<div class="ContentdivHead" onclick="toggleContentDivHead(this,'#divAddEditDealer');">
					<span class="divHeading">Dealer</span>
				</div>
				<div class="clear">
					<div class="ContentdivBorder" id="divAddEditDealer">
						<div class="clear">
							<div class="editor-label FloatLeft" style="width: 40%;">
								<span class="ValidationSpan">*</span> Dealer Name
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.DealerName, new { maxlength = 100, autocomplete = "off", title="Type in Dealer Name" })%>
							</div>
						</div>
						<div class="clear">
							<div class="editor-label FloatLeft" style="width: 40%;">
								<span class="ValidationSpan">*</span> Company Name
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.CompanyName, new { maxlength = 100, autocomplete = "off", title="Type in Company Name" })%>
							</div>
						</div>
						<div class="clear">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Company Short Name
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.CompanyShortForm, new { maxlength = 100, autocomplete = "off", title="Type in Company Short Name" })%>
							</div>
						</div>
						<div class="clear">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Address
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.Address, new { maxlength = 100, autocomplete = "off", title="Type in Address" })%>
							</div>
						</div>
						<div class="clear">
							<div class="editor-label FloatLeft" style="width: 40%;">
								City
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.City, new { maxlength = 100, autocomplete = "off", title="Type in City" })%>
							</div>
						</div>
						<div class="clear">
							<div class="editor-label FloatLeft" style="width: 40%;">
								State
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.State, new { maxlength = 100, autocomplete = "off", title="Type in State" })%>
							</div>
						</div>
						<div class="clear">
							<div class="editor-label FloatLeft" style="width: 40%;">
								PIN Code
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.PinCode, new { maxlength = 6, autocomplete = "off", title="Type in Pin Code" })%>
							</div>
						</div>
						<div class="clear">
							<div class="editor-label FloatLeft" style="width: 40%;">
								VAT or TIN number
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.TinNo, new { maxlength = 100, autocomplete = "off", title="Type in Company VAT or TIN no." })%>
							</div>
						</div>
						<div class="clear">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Mobile Number1
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.MobileNUmber1, new { maxlength = 11, autocomplete = "off", title="Type in mobile no.",style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.MobileNUmber1Com, new { maxlength = 11, autocomplete = "off", title="Type in mobile no. Comment",style="width:100px;" })%> <a class="tmpAddMob" id="add1" onclick="AddMob(this);">
									<img src="../../images/Add.png" /></a>
							</div>
						</div>
						<div class="clear" id="divMob2" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Mobile Number2
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.MobileNUmber2, new { maxlength = 11, autocomplete = "off", title="Type in mobile no.",style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.MobileNUmber2Com, new { maxlength = 11, autocomplete = "off", title="Type in mobile no. Comment",style="width:100px;" })%> <a class="tmpAddMob" id="add2" onclick="AddMob(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="rem2" onclick="RemMob(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.MobileNUmber2, new { id = "hdnMob2"})%>
							</div>
						</div>
						<div class="clear" id="divMob3" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Mobile Number3
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.MobileNUmber3, new { maxlength = 11, autocomplete = "off", title="Type in mobile no.",style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.MobileNUmber3Com, new { maxlength = 11, autocomplete = "off", title="Type in mobile no. Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a1" onclick="AddMob(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A2" onclick="RemMob(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.MobileNUmber3, new { id = "hdnMob3"})%>
							</div>
						</div>
						<div class="clear" id="divMob4" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Mobile Number4
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.MobileNUmber4, new { maxlength = 11, autocomplete = "off", title="Type in mobile no." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.MobileNUmber4Com, new { maxlength = 11, autocomplete = "off", title="Type in mobile no. Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a3" onclick="AddMob(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A4" onclick="RemMob(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.MobileNUmber4, new { id = "hdnMob4"})%>
							</div>
						</div>
						<div class="clear" id="divMob5" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Mobile Number5
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.MobileNUmber5, new { maxlength = 11, autocomplete = "off", title="Type in mobile no.",style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.MobileNUmber5Com, new { maxlength = 11, autocomplete = "off", title="Type in mobile no. Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a5" onclick="AddMob(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A6" onclick="RemMob(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.MobileNUmber5, new { id = "hdnMob5"})%>
							</div>
						</div>
						<div class="clear" id="divMob6" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Mobile Number6
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.MobileNUmber6, new { maxlength = 11, autocomplete = "off", title="Type in mobile no." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.MobileNUmber6Com, new { maxlength = 11, autocomplete = "off", title="Type in mobile no. Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a7" onclick="AddMob(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A8" onclick="RemMob(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.MobileNUmber6, new { id = "hdnMob6"})%>
							</div>
						</div>
						<div class="clear" id="divMob7" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Mobile Number7
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.MobileNUmber7, new { maxlength = 11, autocomplete = "off", title="Type in mobile no." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.MobileNUmber7Com, new { maxlength = 11, autocomplete = "off", title="Type in mobile no. Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a9" onclick="AddMob(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A10" onclick="RemMob(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.MobileNUmber7, new { id = "hdnMob7"})%>
							</div>
						</div>
						<div class="clear" id="divMob8" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Mobile Number8
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.MobileNUmber8, new { maxlength = 11, autocomplete = "off", title="Type in mobile no." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.MobileNUmber8Com, new { maxlength = 11, autocomplete = "off", title="Type in mobile no. Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a11" onclick="AddMob(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A12" onclick="RemMob(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.MobileNUmber8, new { id = "hdnMob8"})%>
							</div>
						</div>

						<div class="clear" id="divMob9" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Mobile Number9
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.MobileNUmber9, new { maxlength = 11, autocomplete = "off", title="Type in mobile no." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.MobileNUmber9Com, new { maxlength = 11, autocomplete = "off", title="Type in mobile no. Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a13" onclick="AddMob(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A14" onclick="RemMob(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.MobileNUmber9, new { id = "hdnMob9"})%>
							</div>
						</div>
						<div class="clear" id="divMob10" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Mobile Number10
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.MobileNUmber10, new { maxlength = 11, autocomplete = "off", title="Type in mobile no." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.MobileNUmber10Com, new { maxlength = 11, autocomplete = "off", title="Type in mobile no. Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a15" onclick="AddMob(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A16" onclick="RemMob(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.MobileNUmber10, new { id = "hdnMob10"})%>
							</div>
						</div>
						<div class="clear">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Email Address1
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.Email1, new { maxlength = 100, autocomplete = "off", title="Type in Email Address." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.Email1Com, new { maxlength = 11, autocomplete = "off", title="Type in email Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a19" onclick="AddMail(this);">
									<img src="../../images/Add.png" /></a>
							</div>
						</div>
						<div class="clear" id="divMail2" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Email Address2
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.Email2, new { maxlength = 100, autocomplete = "off", title="Type in Email Address.",style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.Email2Com, new { maxlength = 11, autocomplete = "off", title="Type in email Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a17" onclick="AddMail(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A18" onclick="RemMail(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.Email2, new { id = "hdnMail2"})%>
							</div>
						</div>
						<div class="clear" id="divMail3" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Email Address3
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.Email3, new { maxlength = 100, autocomplete = "off", title="Type in Email Address." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.Email3Com, new { maxlength = 11, autocomplete = "off", title="Type in email Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a20" onclick="AddMail(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A21" onclick="RemMail(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.Email3, new { id = "hdnMail3"})%>
							</div>
						</div>
						<div class="clear" id="divMail4" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Email Address4
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.Email4, new { maxlength = 100, autocomplete = "off", title="Type in Email Address." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.Email4Com, new { maxlength = 11, autocomplete = "off", title="Type in email Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a22" onclick="AddMail(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A23" onclick="RemMail(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.Email4, new { id = "hdnMail4"})%>
							</div>
						</div>
						<div class="clear" id="divMail5" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Email Address5
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.Email5, new { maxlength = 100, autocomplete = "off", title="Type in Email Address." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.Email5Com, new { maxlength = 11, autocomplete = "off", title="Type in email Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a24" onclick="AddMail(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A25" onclick="RemMail(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.Email5, new { id = "hdnMail5"})%>
							</div>
						</div>
						<div class="clear" id="divMail6" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Email Address6
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.Email6, new { maxlength = 100, autocomplete = "off", title="Type in Email Address." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.Email6Com, new { maxlength = 11, autocomplete = "off", title="Type in email Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a26" onclick="AddMail(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A27" onclick="RemMail(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.Email6, new { id = "hdnMail6"})%>
							</div>
						</div>
						<div class="clear" id="divMail7" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Email Address7
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.Email7, new { maxlength = 100, autocomplete = "off", title="Type in Email Address." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.Email7Com, new { maxlength = 11, autocomplete = "off", title="Type in email Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a28" onclick="AddMail(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A29" onclick="RemMail(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.Email7, new { id = "hdnMail7"})%>
							</div>
						</div>
						<div class="clear" id="divMail8" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Email Address8
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.Email8, new { maxlength = 100, autocomplete = "off", title="Type in Email Address." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.Email8Com, new { maxlength = 11, autocomplete = "off", title="Type in email Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a30" onclick="AddMail(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A31" onclick="RemMail(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.Email8, new { id = "hdnMail8"})%>
							</div>
						</div>
						<div class="clear" id="divMail9" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Email Address9
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.Email9, new { maxlength = 100, autocomplete = "off", title="Type in Email Address." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.Email9Com, new { maxlength = 11, autocomplete = "off", title="Type in email Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a32" onclick="AddMail(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A33" onclick="RemMail(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.Email9, new { id = "hdnMail9"})%>
							</div>
						</div>
						<div class="clear" id="divMail10" style="display: none;">
							<div class="editor-label FloatLeft" style="width: 40%;">
								Email Address10
							</div>
							<div class="editor-field" style="text-align: left;">
								<%= Html.TextBoxFor(m => m.Email10, new { maxlength = 100, autocomplete = "off", title="Type in Email Address." ,style="width:93px;" })%>&nbsp;<%= Html.TextBoxFor(m => m.Email10Com, new { maxlength = 11, autocomplete = "off", title="Type in email Comment",style="width:100px;" })%> <a class="tmpAddMob" id="a34" onclick="AddMail(this);">
									<img src="../../images/Add.png" /></a><a class="tmpRemMob" id="A35" onclick="RemMail(this);">
										<img src="../../images/remove.png" /></a>
								<%= Html.HiddenFor(m => m.Email10, new { id = "hdnMail10"})%>
							</div>
						</div>
						<div>
							<div id="divDealerBankDetails">
							</div>
						</div>
						<div id="divButtons" class="clear" style="margin-top: 10px; margin-bottom: 20px;">
							<center>
                                <input type="button" value="<%= Model.BtnText %>" class="rg_button_red" onclick="submitDealer(); return false;" />
                                <input type="button" value="Clear" class="rg_button" onclick="clearForm(); return false;" />
                                <%= Html.HiddenFor(m => m.Id, new { id = "hdnID"})%>
                            </center>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</body>
</html>
