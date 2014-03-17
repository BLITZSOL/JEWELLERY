﻿<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage<THSMVC.Models.EditQuestionModel>" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>TrueFalseEdit</title>
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
        function UpdateTFQuestion() {
            ClearMsg();
            if ($('#question').length && $('#question').val().length) {
                var msg;
                msg = "";
                /* Ans 1 and 2 must have values */
                if ($('#tfans1').val().length == 0 || $('#tfans2').val().length == 0) {
                    msg = msg + 'You must fill in both answer boxes.<br/>';
                }
                if ($("input[type=radio]:checked").length != 1) {
                    msg = msg + 'You must select an answer.<br/>';
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
                    url: "/OnlineTest/UpdateTFQuestion",
                    data: {
                        TestId: $("#hdnValTestId").val(),
                        Question: $("#question").val(),
                        QuestionId: $("#hdnQId").val(),
                        QuestionType: $("#hdnQtypeId").val(),
                        Answer1: $("#tfans1").val(),
                        AnswerId1: $("#hdnAId1").val(),
                        CorrectAnswer1: $("input[type=radio][id=tf1]").is(':checked'),
                        Answer2: $("#tfans2").val(),
                        AnswerId2: $("#hdnAId2").val(),
                        CorrectAnswer2: $("input[type=radio][id=tf2]").is(':checked'),
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
                            $("#tfans1").val("");
                            $("#tfans2").val("");
                            $("input[type=radio][id=tf1]").attr("checked", false);
                            $("input[type=radio][id=tf2]").attr("checked", false);
                            $("#CategoryId").val("");
                            $("#points").val("1");
                            window.scroll(0, 0);
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
        function BackToTestSearch() {
            var TestId = $("#hdnTestId").val();
            LoadContentByActionAndControllerForEdit("ManageTest", "OnlineTest", "Manage Test", TestId);
        }
    </script>
</head>
<body>
    <div id="obj_ref" style="display: none;">
    </div>
    <div id="basic-modal-content">
    </div>
    <%= Html.HiddenFor(m => m.QuestiontypeId, new { id = "hdnQtypeId" })%>
    <%= Html.HiddenFor(m => m.QuestionId, new { id = "hdnQId" })%>
    <div id="divbackToSearch" style="float: left;">
        <input type="button" class="rg_button_red upper" title="Back to test" value="Back To test"
            onclick="BackToTestSearch()" />
        <%= Html.HiddenFor(m => m.TestId, new { id="hdnTestId" })%>
    </div>
    <div class="clear">
        <h2>
            Update True/False Answer Question</h2>
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
                    <%= Html.TextAreaFor(m => m.question.ToList()[0].Question, new { id = "question",name="question", style = "width: 265px; margin-bottom: 10px;", rows = "3", cols = "5" })%>
                    <br />
                </div>
                <% int cnt;
                   for (cnt = 0; cnt <= 1; cnt++)
                   {
                %>
                <div class="boxinline">
                    <p class="titlename">
                        <strong>Answer</strong></p>
                    <%if (Convert.ToBoolean(Model.question.ToList()[cnt].IsCorrect))
                      { %>
                    <input type="radio" id="tf<%=cnt+1 %>" checked="checked" name="correct" value="<%=cnt+1 %>" />
                    <%= Html.HiddenFor(m => m.question.ToList()[cnt].AnswerId, new { id = "hdnAId"  +(cnt + 1) })%>
                    <%}
                       else
                       { %>
                    <input type="radio" id="tf<%=cnt+1 %>" name="correct" value="<%=cnt+1 %>" />
                    <%= Html.HiddenFor(m => m.question.ToList()[cnt].AnswerId, new { id = "hdnAId"  +(cnt + 1) })%>
                    <%} %>
                    This is correct answer<br />
                    <%= Html.TextBoxFor(m => m.question.ToList()[cnt].Answer, new { id = "tfans" + (cnt + 1), size = "30" })%>
                </div>
                <%} %>
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
        <input type="button" class="rg_button_red" title="Save" value="Update Question" onclick="UpdateTFQuestion();" />
    </div>
    <script type="text/javascript">
        webpath_img = '../images/';
        letters = Array('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J');
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

                num = 1;
                $("input[type=radio][name=correct]").each(function (index) {

                    /* See if radio button is checked */
                    if ($(this).is(':checked')) {
                        gif = '<img src="' + webpath_img + 'correct.gif" alt="Correct">';
                    } else {
                        gif = '';
                    }
                    preview_html += '<tr class="qs"><td>' + gif + '</td><td class="number">' + letters[num - 1] + ')</td><td class="answer">' + $('#tfans' + num).val() + '</td></tr>';

                    num++;
                });
                preview_html += '</table><div class="clearheight"></div></div>';
                $("#divPreviewQuestion").html('');
                $("#divPreviewQuestion").html(preview_html);
            });
        });
    </script>
</body>
</html>
