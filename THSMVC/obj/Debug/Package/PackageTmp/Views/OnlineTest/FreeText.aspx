﻿<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage<THSMVC.Models.CreateTestModel>" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>FreeText</title>
    <style type="text/css">
        .gray
        {
            color: #4D4D4D;
        }
        .question_edit_tab
        {
            padding: 6px 0 0 35px;
            background: white;
            float: left;
            width: 140px;
            border-top: 1px solid #C7C7C7;
            border-left: 1px solid #C7C7C7;
            border-right: 1px solid #C7C7C7;
        }
        .question_preview_tab
        {
            padding: 6px 0 0 35px;
            background: whiteSmoke;
            float: left;
            width: 140px;
            border-top: 1px solid #E2E2E2;
            border-left: 1px solid #E2E2E2;
            border-right: 1px solid #E2E2E2;
            border-bottom: 1px solid #C7C7C7;
        }
        .boxinline
        {
            border: 1px solid #D0D2D2;
            background: url(../images/grad_inline.gif) bottom left repeat-x;
            margin: 10px 0 10px 0;
            padding: 10px;
            width: 500px;
        }
        p
        {
            display: block;
            -webkit-margin-before: 1em;
            -webkit-margin-after: 1em;
            -webkit-margin-start: 0px;
            -webkit-margin-end: 0px;
        }
        .titlename
        {
            font-size: 1.1em;
            line-height: 1.3em;
        }
        .toolbar
        {
            margin: 0;
            padding: 2px 2px 2px 0;
        }
        .dotted
        {
            color: white;
            clear: both;
            float: none;
            height: 1px;
            margin: 5px 0 10px 0;
            padding: 0;
            border-bottom: 1px dotted #D2D2D2;
        }
        .answholder
        {
            font-size: 1.125em;
        }
        .qsholder td, .answholder td
        {
            vertical-align: top;
        }
    </style>
    <script type="text/javascript">
        function SaveftQuestion() {
            ClearMsg();
            if ($('#question').length && $('#question').val().length) {
                var msg;
                msg = "";
                /* Ans 1 must have values */
                if ($('#ftans1').val().length == 0) {
                    msg = msg + 'You must fill in at least the first answer box.<br/>';
                }
                /* If a answer is blank yet one after has value give a missing answer error */
                prev_answer_blank = false;
                fail = false;
                $('[id^="ftans"]').each(function (index) {
                    if ($(this).val().length > 0 && prev_answer_blank == true) {
                        fail = true;
                        return false;
                    }
                    if ($(this).val().length == 0) {
                        prev_answer_blank = true;
                    }
                });
                if (fail != false) {
                    msg = msg + 'You have an answer missing before your last entered answer. Answers must be entered directly after each other.<br/>';
                }
                if ($("#CategoryId").val() == "") {
                    msg = msg + 'Please select Category for this question.<br/>';
                }
                if ($("#points").val() == "") {
                    msg = msg + 'Please enter points for this question';
                }
                if (msg != "") {
                    Failure(msg);
                    return false;
                }
                $.ajax({
                    type: "POST",
                    traditional: true,
                    url: "/OnlineTest/SaveFTQuestion",
                    data: {
                        TestId: $("#hdnValTestId").val(),
                        Question: $("#question").val(),
                        QuestionType: $("#hdnQtypeId").val(),
                        Answer1: $("#ftans1").val(),
                        Answer2: $("#ftans2").val(),
                        Answer3: $("#ftans3").val(),
                        Answer4: $("#ftans4").val(),
                        Answer5: $("#ftans5").val(),
                        CategoryId: $("#CategoryId").val(),
                        Points: $("#points").val()
                    },
                    dataType: "json",
                    beforeSend: function () {
                        $.blockUI();   //this is great plugin - 'blockUI'
                    },
                    success: function (result) {
                        if (result.success) {
                            ClearMsg();
                            Success(result.message);
                            $("#question").val("");
                            $("#ftans1").val("");
                            $("#ftans2").val("");
                            $("#ftans3").val("");
                            $("#ftans4").val("");
                            $("#ftans5").val("");
                            $("#CategoryId").val("");
                            $("#points").val("1");
                        }
                        else {
                            Failure(result.message);
                        }
                        $.unblockUI();
                    },
                    error: function (XMLHttpRequest, textStatus, errorThrown) {
                        $.unblockUI();
                        Error(XMLHttpRequest, textStatus, errorThrown);
                    }
                });
            }
            else {
                Failure("You have not entered a question.");
                return false;
            }

        }
    </script>
</head>
<body>
    <div id="obj_ref" style="display: none;">
    </div>
    <div id="basic-modal-content">
    </div>
    <%= Html.HiddenFor(m => m.Test, new { id = "hdnValTestId" })%>
    <%= Html.HiddenFor(m => m.Qtype, new { id="hdnQtypeId"})%>
    <div class="clear">
        <h2>
            Add Free Text Question</h2>
        <div class="question_edit_tab" id="question_edit_tab1">
            <p>
                <a href="#"><span>Edit Question</span></a></p>
        </div>
        <div class="question_preview_tab" id="question_preview_tab1">
            <p>
                <a href="#"><span>Preview Question</span></a></p>
        </div>
        <div id="divEditQuestion">
            <div class="clear">
                <div class="boxinline">
                    <p class="titlename">
                        <strong>Question</strong></p>
                    <div id="tb_question" class="edtoolbar">
                    </div>
                    <textarea id="question" style="width: 265px; margin-bottom: 10px;" rows="3" cols="5"
                        name="question"></textarea><br />
                </div>
                <div class="boxinline">
                    <p class="titlename">
                        <strong>Accepted answers</strong></p>
                    <p class="titlename">
                        Add each separate accepted answer per box</p>
                    <p class="gray">
                        Users will not see these when answering this question.</p>
                    <p>
                        <input type="text" name="ans1" size="30" id="ftans1" value="" />
                        Mandatory</p>
                    <p>
                        <input type="text" name="ans2" size="30" id="ftans2" value="" />
                        Optional</p>
                    <p>
                        <input type="text" name="ans3" size="30" id="ftans3" value="" />
                        Optional</p>
                    <p>
                        <input type="text" name="ans4" size="30" id="ftans4" value="" />
                        Optional</p>
                    <p>
                        <input type="text" name="ans5" size="30" id="ftans5" value="" />
                        Optional</p>
                </div>
            </div>
        </div>
        <div id="divPreviewQuestion">
        </div>
        <div class="boxinline">
            <p class="titlename">
                <strong>Category</strong></p>
            <p>
                Select the category for this question</p>
            <p class="gray">
                Add categories via the "Online Test / Categories" section.</p>
            <%= Html.DropDownListFor(m => m.CategoryId, Model.Categories, "Select Category", new { title = "Select the Category" })%>
        </div>
        <div class="boxinline">
            <p class="titlename">
                <strong>Points available</strong></p>
            <p class="gray">
                Decimals are allowed<br />
                Examples: 1 or 2.5</p>
            <p class="titlename">
                <input type="text" maxlength="5" value="1" id="points" name="points" /></p>
        </div>
        <input type="button" class="rg_button_red" title="Save" value="Save Question" onclick="SaveftQuestion();" />
    </div>
    <script type="text/javascript">
        $(document).ready(function () {
            $(".edtoolbar").each(function (e) {
                id = this.id.substring(3);
                tooBarHtml = "<div class=\"toolbar\">"
		+ "<img class=\"toolbar\" src=\"../../images/BBCode_Images/bold.gif\" name=\"btnBold\" alt=\"Bold\" onclick=\"doAddTags('[b]','[/b]','" + id + "')\">"
		+ "<img class=\"toolbar\" src=\"../../images/BBCode_Images/italic.gif\" name=\"btnItalic\" alt=\"Italic\" onclick=\"doAddTags('[i]','[/i]','" + id + "')\">"
		+ "<img class=\"toolbar\" src=\"../../images/BBCode_Images/underline.gif\" name=\"btnUnderline\" alt=\"Underline\" onclick=\"doAddTags('[u]','[/u]','" + id + "')\">"
		+ "<img class=\"toolbar\" src=\"../../images/BBCode_Images/strike.gif\" name=\"btnStrike\" alt=\"Line-through\" onclick=\"doAddTags('[s]','[/s]','" + id + "')\">"
		+ "<img class=\"toolbar\" src=\"../../images/BBCode_Images/sub.gif\" name=\"btnSub\" alt=\"Subscript\" onclick=\"doAddTags('[sub]','[/sub]','" + id + "')\">"
		+ "<img class=\"toolbar\" src=\"../../images/BBCode_Images/sup.gif\" name=\"btnSup\" alt=\"Superscript\" onclick=\"doAddTags('[sup]','[/sup]','" + id + "')\">"
		+ "<img class=\"toolbar\" src=\"../../images/BBCode_Images/sqroot.gif\" name=\"btnSqr\" alt=\"Square root\" onclick=\"sqRoot('" + id + "')\">"
		+ "<img class=\"toolbar\" src=\"../../images/BBCode_Images/link.gif\" name=\"btnLink\" alt=\"Insert URL Link\" onclick=\"doURL('" + id + "')\">"
                //"<img class=\"toolbar\" src=\"../../images/BBCode_Images/color.gif\" name=\"btnColor\" alt=\"Text color\" onclick=\"doColor('" + id + "')\">"
		+ "<img class=\"toolbar\" src=\"../../images/BBCode_Images/color.gif\" name=\"btnColor\" alt=\"Text color\" id=\"selectColor_" + id + "\" onclick=\"ChooseColorPopUp('" + id + "');\">"
                //"<img class=\"button\" src=\"../../images/BBCode_Images/img.gif\" name=\"btnPicture\" alt=\"Insert Image\" onclick=\"doImage('" + id + "')\">"
		+ "<img class=\"toolbar\" src=\"../../images/BBCode_Images/img.gif\" name=\"btnPicture\" alt=\"Insert Image\" id=\"selectDoc_" + id + "\" onclick=\"ChooseYTPopUp('" + id + "');\">"
		+ "<img class=\"toolbar\" src=\"../../images/BBCode_Images/youtube.gif\" name=\"btnYouTube\" alt=\"YouTube ID\" id=\"selectYt_" + id + "\" onclick=\"ChooseYTPopUp('" + id + "');\">"
		+ "</div>";
                $(this).html(tooBarHtml);
            });

            $("#question_edit_tab1").click(function () {
                $("#divEditQuestion").show();
                $("#divPreviewQuestion").hide();
                $("#question_preview_tab1").attr("class", "question_preview_tab");
                $("#question_edit_tab1").attr("class", "question_edit_tab");
            });
            $("#question_preview_tab1").click(function () {
                $("#divEditQuestion").hide();
                $("#divPreviewQuestion").show();
                $("#question_edit_tab1").attr("class", "question_preview_tab");
                $("#question_preview_tab1").attr("class", "question_edit_tab");
                preview_html = '<div class="clear"><h3>Preview question</h3>';

                preview_html += '<p class="col600 qsholder">';
                /* question */
                if ($('#question').length && $('#question').val().length) {
                    preview_html += bbCode(replaceLineBreak($('#question').val()));
                }
                /* MC Answers */
                preview_html += '</p><div class="dotted"></div>';
                preview_html += '<table class="answholder" cellpadding="0" cellspacing="0">';

                /* FT - Loop through existing ans fields on the page */
                if ($('#ftans1').length) {
                    preview_html += '<tr class="qs"><td></td><td class="number"></td><td class="answer"><p class="gray">Accepted answers</p></td></tr>';
                }
                $('[id^="ftans"]').each(function (index) {
                    num = this.id.substring(5);
                    if ($(this).val().length) {
                        preview_html += '<tr class="qs"><td><img src="' + webpath_img + 'correct.gif" alt="Correct"></td><td class="number"></td><td class="answer">' + $(this).val() + '</td></tr>';
                    }
                });
                preview_html += '</table><div class="clearheight"></div></div>';
                $("#divPreviewQuestion").html('');
                $("#divPreviewQuestion").html(preview_html);
            });
        });
    </script>
</body>
</html>