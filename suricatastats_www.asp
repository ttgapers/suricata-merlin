<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>Suricata Statistics</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<style>
p{
font-weight: bolder;
}

.collapsible {
  color: white;
  padding: 0px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  cursor: pointer;
}	

th.keystatsnumber {
  font-size: 20px !important;
  font-weight: bolder !important;
}

.StatsTable {
  table-layout: fixed !important;
  width: 747px !important;
  text-align: center !important;
}
.StatsTable th {
  background-color:#1F2D35 !important;
  background:#2F3A3E !important;
  border-bottom:none !important;
  border-top:none !important;
  font-size: 12px !important;
  color: white !important;
  padding: 4px !important;
  width: 740px !important;
}
.StatsTable td {
  padding: 2px !important;
  word-wrap: break-word !important;
  overflow-wrap: break-word !important;
}
.StatsTable a {
  font-weight: bolder !important;
  text-decoration: underline !important;
}
.StatsTable th:first-child,
.StatsTable td:first-child {
  border-left: none !important;
}
.StatsTable th:last-child ,
.StatsTable td:last-child {
  border-right: none !important;
}

</style>
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/moment.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chart.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/hammerjs.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-zoom.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-annotation.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmhist.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmmenu.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/suricata_stats.sh/suricatastatstitle.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/suricata_stats.sh/suricatastats.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/suricata_stats.sh/suricatahits.js"></script>


<script>
// Keep the real data in a seperate object called allData
// Put only that part of allData in the dataset to optimize zoom/pan performance
// Author: Evert van der Weit - 2018
function filterData(chartInstance) {
	var datasets = chartInstance.data.datasets;
	var originalDatasets = chartInstance.data.allData;
	var chartOptions = chartInstance.options.scales.xAxes[0];
	
	var startX = chartOptions.time.min;
	var endX = chartOptions.time.max;
	if(typeof originalDatasets === 'undefined' || originalDatasets === null) { return; }
	for(var i = 0; i < originalDatasets.length; i++) {
		var dataset = datasets[i];
		var originalData = originalDatasets[i];
		
		if (!originalData.length) break
		
		var s = startX;
		var e = endX;
		var sI = null;
		var eI = null;
		
		for (var j = 0; j < originalData.length; j++) {
			if ((sI==null) && originalData[j].x > s) {
				sI = j;
			}
			if ((eI==null) && originalData[j].x > e) {
				eI = j;
			}
		}
		if (sI==null) sI = 0;
		if (originalData[originalData.length - 1].x < s) eI = 0
			else if (eI==null) eI = originalData.length
		
		dataset.data = originalData.slice(sI, eI);
	}
}
var datafilterPlugin = {
	beforeUpdate: function(chartInstance) {
		filterData(chartInstance);
	}
}

/* create and return new array padding missing days*/
function FillEmptyDates(startDay, endDay, data) {
  var strStart = startDay.getFullYear() + "-" + (startDay.getMonth()+1) + "-" + startDay.getDate();
  var momStart = moment(strStart, "YYYY-MM-DD");
  var strEnd = endDay.getFullYear() + "-" + (endDay.getMonth()+1) + "-" + endDay.getDate();
  var momEnd = moment(strEnd, "YYYY-MM-DD");
  if (data.length > 0) // non-empty array
  {
    // empty value at start date for visutals
    var startDiff = dateDiff(momStart, data[0].x);
    if (startDiff >= 1)
    {
      var fillData = { x: moment(momStart), y: 0 };
      data.unshift(fillData);
    }
    // empty value at end date for visuals
    var endDiff = dateDiff(data[data.length-1].x, momEnd);
    if (endDiff >= 1)
    {
      var fillData = { x: moment(momEnd), y: 0 };
      data.push(fillData);
    }
  } else { // empty array

      var fillData = { x: moment(momStart), y: 0 };
      data.unshift(fillData);
      var fillData2 = { x: moment(momEnd), y: 0 };
      data.push(fillData2);
  }
  newData = [data[0]];

  for (i = 1; i < data.length; i++) {
    var diff = dateDiff(data[i - 1].x, data[i].x);
    var startDate = new Date(data[i - 1].x);
    if (diff > 1) {
      for (j = 0; j < diff - 1; j++) {
        var fillDate = new Date(startDate);
        fillDate.setDate(fillDate.getDate() + (j+1));
        var fillData = { x: moment(fillDate), y: 0 };
          newData.push(fillData);
      }
    }
    newData.push(data[i]);
  }
  return newData;
}


/* helper function to find date differences*/
function dateDiff(d1, d2) {
  return Math.floor((d2 - d1) / (1000 * 60 * 60 * 24));
}

var BarChartHistogram, BarChartAnswers, BarChartTopBlocked, BarChartTopReplies;
var charttypehistogram, charttypeanswers, charttypetopblocked, charttypetopreplies;
var ShowLines=GetCookie("ShowLines");
var ShowFill=GetCookie("ShowFill");
Chart.defaults.global.defaultFontColor = "#CCC";
Chart.Tooltip.positioners.cursor = function(chartElements, coordinates) {
  return coordinates;
};
function Draw_Chart_NoData(txtchartname){
	document.getElementById(txtchartname).width="730";
	document.getElementById(txtchartname).height="300";
	document.getElementById(txtchartname).style.width="730px";
	document.getElementById(txtchartname).style.height="300px";
	var ctx = document.getElementById(txtchartname).getContext("2d");
	ctx.save();
	ctx.textAlign = 'center';
	ctx.textBaseline = 'middle';
	ctx.font = "normal normal bolder 48px Arial";
	ctx.fillStyle = 'white';
	ctx.fillText('No data to display', 365, 150);
	ctx.restore();
}
function Draw_Chart(txtchartname,txttitle,txtunity,txtunitx,numunitx,colourname,txtdateformat,sugMinY){
	var objchartname=window["LineChart"+txtchartname];
	var txtdataname="Data"+txtchartname;
	var objdataname=window["Data"+txtchartname];
	if(typeof objdataname === 'undefined' || objdataname === null) { Draw_Chart_NoData(txtchartname); return; }
	if (objdataname.length == 0) { Draw_Chart_NoData(txtchartname); return; }
	factor=0;
	if (txtunitx=="hour"){
		factor=60*60*1000;
	}
	else if (txtunitx=="day"){
		factor=60*60*24*1000;
	}
	if (objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById(txtchartname).getContext("2d");
	var lineOptions = {
		segmentShowStroke : false,
		segmentStrokeColor : "#000",
		animationEasing : "easeOutQuart",
		animationSteps : 100,
		maintainAspectRatio: false,
		animateScale : true,
		legend: { display: false, position: "bottom", onClick: null },
		title: { display: true, text: txttitle },
		tooltips: {
			callbacks: {
					title: function (tooltipItem, data) { return moment(tooltipItem[0].xLabel).format(txtdateformat);},
					label: function (tooltipItem, data) { return data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index].y.toString() + ' ' + txtunity;}
				},
				mode: 'point',
				position: 'cursor',
				intersect: true
		},
		scales: {
			xAxes: [{
				type: "time",
				gridLines: { display: true, color: "#282828" },
				ticks: {
					min: moment().subtract(numunitx, txtunitx+"s"),
					display: true
				},
				time: { unit: txtunitx, stepSize: 1 }
			}],
			yAxes: [{
				gridLines: { display: false, color: "#282828" },
				scaleLabel: { display: false, labelString: txttitle },
				ticks: {
					display: true,
					suggestedMin: sugMinY,
					callback: function (value, index, values) {
						return round(value,2).toFixed(2) + ' ' + txtunity;
					}
				},
			}]
		},
		plugins: {
			zoom: {
				pan: {
					enabled: false,
					mode: 'xy',
					rangeMin: {
						x: new Date().getTime() - (factor * numunitx),
						y: getLimit(txtdataname,"y","min") - Math.sqrt(Math.pow(getLimit(txtdataname,"y","min"),2))*0.1,
					},
					rangeMax: {
						x: new Date().getTime(),
						y: getLimit(txtdataname,"y","max") + getLimit(txtdataname,"y","max")*0.1,
					},
				},
				zoom: {
					enabled: false,
					mode: 'xy',
					rangeMin: {
						x: new Date().getTime() - (factor * numunitx),
						y: getLimit(txtdataname,"y","min") - Math.sqrt(Math.pow(getLimit(txtdataname,"y","min"),2))*0.1,
					},
					rangeMax: {
						x: new Date().getTime(),
						y: getLimit(txtdataname,"y","max") + getLimit(txtdataname,"y","max")*0.1,
					},
					speed: 0.1
				},
			},
		},
		annotation: {
			drawTime: 'afterDatasetsDraw',
			annotations: [{
				id: 'avgline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'y-axis-0',
				value: getAverage(objdataname),
				borderColor: colourname,
				borderWidth: 1,
				borderDash: [5, 5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: "sans-serif",
					fontSize: 10,
					fontStyle: "bold",
					fontColor: "#fff",
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: "center",
					enabled: true,
					xAdjust: 0,
					yAdjust: 0,
					content: "Avg=" + round(getAverage(objdataname),2).toFixed(2)+txtunity,
				}
			},
			{
				id: 'maxline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'y-axis-0',
				value: getLimit(txtdataname,"y","max"),
				borderColor: colourname,
				borderWidth: 1,
				borderDash: [5, 5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: "sans-serif",
					fontSize: 10,
					fontStyle: "bold",
					fontColor: "#fff",
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: "center",
					enabled: true,
					xAdjust: 0,
					yAdjust: 0,
					content: "Max=" + round(getLimit(txtdataname,"y","max"),2).toFixed(2)+txtunity,
				}
			},
			{
				id: 'minline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'y-axis-0',
				value: getLimit(txtdataname,"y","min"),
				borderColor: colourname,
				borderWidth: 1,
				borderDash: [5, 5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: "sans-serif",
					fontSize: 10,
					fontStyle: "bold",
					fontColor: "#fff",
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: "center",
					enabled: true,
					xAdjust: 0,
					yAdjust: 0,
					content: "Min=" + round(getLimit(txtdataname,"y","min"),2).toFixed(2)+txtunity,
				}
			}]
		}
	};
	var lineDataset = {
		datasets: [{data: objdataname,
			label: txttitle,
			borderWidth: 2,
			pointRadius: 3,
			lineTension: 0.3,
			fill: ShowFill,
			backgroundColor: colourname,
			borderColor: colourname,
		}]
	};
	objchartname = new Chart(ctx, {
		type: 'line',
		plugins: [datafilterPlugin],
		options: lineOptions,
		data: lineDataset
	});
	window[txtchartname]=objchartname;
}
function getLimit(datasetname,axis,maxmin) {
	limit=0;
	eval("limit=Math."+maxmin+".apply(Math, "+datasetname+".map(function(o) { return o."+axis+";} ))");
	return limit;
}
function getAverage(datasetname) {
	var total = 0;
	for(var i = 0; i < datasetname.length; i++) {
		total += datasetname[i].y;
	}
	var avg = total / datasetname.length;
	return avg;
}
function round(value, decimals) {
	return Number(Math.round(value+'e'+decimals)+'e-'+decimals);
}
function ToggleLines() {
	if(ShowLines == ""){
		ShowLines = "line";
		SetCookie("ShowLines","line");
	}
	else {
		ShowLines = "";
		SetCookie("ShowLines","");
	}
	RedrawAllCharts();
}
function ToggleFill() {
	if(ShowFill == false){
		ShowFill = "origin";
		SetCookie("ShowFill","origin");
	}
	else {
		ShowFill = false;
		SetCookie("ShowFill",false);
	}
	RedrawAllCharts();
}
function RedrawAllCharts() {
	Draw_Chart("divLineChartThreatsMonthly","Threats Detected","threat (s)","day",30,"#ffffff",'YYYY-MM-DD',0);
}
function GetCookie(cookiename) {
	var s;
	if ((s = cookie.get("suricata_"+cookiename)) != null) {
		return cookie.get("suricata_"+cookiename);
	}
	else {
		return "";
	}
}
function SetCookie(cookiename,cookievalue) {
	cookie.set("suricata_"+cookiename, cookievalue, 31);
}

function GetCookieNew(cookiename,default_value) {
	var s;
	if ((s = cookie.get(cookiename)) != null) {
			if (s.match(/^([0-2])$/)) {
				E(cookiename).value = cookie.get(cookiename) * 1;
			}
	} else {
		E(cookiename).value = default_value;
	}
}

function SetCurrentPage(){
	document.form.next_page.value = window.location.pathname.substring(1);
	document.form.current_page.value = window.location.pathname.substring(1);
}

function initial(){
	SetCurrentPage();
	show_menu();
	SetSuricataStatsTitle();

	// redraw the Threats graphs
	var startDate = new Date();
	var endDate = new Date();
	startDate.setDate(startDate.getDate() - 30);
	DatadivLineChartThreatsMonthly = FillEmptyDates(startDate, endDate, DatadivLineChartThreatsMonthly);
	RedrawAllCharts();

	// load tables
	LoadThreatsTable();

	$("thead").click(function(){
		$(this).siblings().toggle("fast");
	})
	
	$(".default-collapsed").trigger("click");
}

function get_BarChart(name) {
	if ("ChartHistogram" == name) {
		return BarChartHistogram;
	} else if ("ChartAnswers" == name) {
		return BarChartAnswers;
	} else if ("ChartTopBlocked" == name) {
		return BarChartTopBlocked;
	} else if ("ChartTopReplies" == name) {
		return BarChartTopReplies;
	} else {
		return NULL;
	}
}

function set_BarChart(name, value) {
	if ("ChartHistogram" == name) {
		BarChartHistogram = value;
	} else if ("ChartAnswers" == name) {
		BarChartAnswers = value;
	} else if ("ChartTopBlocked" == name) {
		BarChartTopBlocked = value;;
	} else if ("ChartTopReplies" == name) {
		BarChartTopReplies = value;;
	}
}

function reload() {
	location.reload(true);
}

function applyRule() {
	var action_script_tmp = "start_suricata_stats.sh";
	document.form.action_script.value = action_script_tmp;
	var restart_time = document.form.action_wait.value*1;
	showLoading();
	document.form.submit();
}

function Draw_Bar_Chart(barLabels, barData, ChartName, charttype, colourtag) {
	if(typeof barLabels === 'undefined' || barLabels === null || (Array.isArray(barLabels) && barLabels.length == 0)) { Draw_Chart_NoData(ChartName); return; }
	if(typeof barData === 'undefined' || barData === null || (Array.isArray(barData) && barData.length == 0)) { Draw_Chart_NoData(ChartName); return; }
	if (barLabels.length == 0) { Draw_Chart_NoData(ChartName); return; }
	var BarChartName = get_BarChart(ChartName);
	if (BarChartName != undefined) BarChartName.destroy();
	var ctx = document.getElementById(ChartName).getContext("2d");
	var barOptions = {
		segmentShowStroke : false,
		segmentStrokeColor : "#000",
		animationEasing : "easeOutQuart",
		animationSteps : 100,
		maintainAspectRatio: false,
		animateScale : true,
		legend: { display: false, position: "bottom", onClick: null },
		title: { display: false },
		tooltips: {
			callbacks: {
				title: function (tooltipItem, data) { return data.labels[tooltipItem[0].index]; },
				label: function (tooltipItem, data) { return comma(data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index]); },
			},
			mode: 'point',
			position: 'cursor',
			intersect: true
		},
		scales: {
			xAxes: [{
				display: showAxis(charttype,"x"),
				gridLines: { display: showGrid(charttype,"x"), color: "#282828" },
				ticks: { display: showAxis(charttype,"x"), beginAtZero: false }
			}],
			yAxes: [{
				display: showAxis(charttype,"y"),
				gridLines: { display: false, color: "#282828" },
				scaleLabel: { display: false, labelString: "Blocks" },
				ticks: { display: showAxis(charttype,"y"), beginAtZero: false }
			}]
		},
		plugins: {
			zoom: {
				pan: {
					enabled: false,
					mode: ZoomPanEnabled(charttype),
					rangeMin: {
						x: 0,
						y: 0
					},
					rangeMax: {
						x: ZoomPanMax(charttype,"x",barData),
						y: ZoomPanMax(charttype,"y",barData)
					},
				},
				zoom: {
					enabled: false,
					mode: ZoomPanEnabled(charttype),
					rangeMin: {
						x: 0,
						y: 0
					},
					rangeMax: {
						x: ZoomPanMax(charttype,"x",barData),
						y: ZoomPanMax(charttype,"y",barData)
					},
					speed: 0.1,
				}
			}
		}
	};
	var barDataset = {
		labels: barLabels,
		datasets: [{data: barData,
			borderWidth: 1,
			backgroundColor: poolColors(barData.length),
			borderColor: "#000000",
		}]
	};
	BarChartName = new Chart(ctx, {
		type: getChartType(charttype),
		options: barOptions,
		data: barDataset
	});
	set_BarChart(ChartName, BarChartName);
	changeColour(E(colourtag),BarChartName,barData,colourtag)
}

function changeColour(e,chartname,datasetname,cookiename) {
	colour = e.value * 1;
	if ( colour == 0 ) {
		chartname.config.data.datasets[0].backgroundColor = poolColors(datasetname.length);
	}
	else {
		chartname.config.data.datasets[0].backgroundColor = "rgba(2, 53, 135, 1)";
	}
	cookie.set(cookiename, colour, 31);
	chartname.update();
}

function changeLayout(e,chartname,cookiename) {
	layout = e.value * 1;
	if ( layout == 0 ) {
		if ( chartname == "BarChartHistogram" ) {
			charttypehistogram = "horizontalBar";
		}
		else if ( chartname == "BarChartAnswers" ) {
			charttypeanswers = "horizontalBar";
		}
		else if ( chartname == "BarChartTopBlocked" ) {
			charttypetopblocked = "horizontalBar";
		}
		else if ( chartname == "BarChartTopReplies" ) {
			charttypetopreplies = "horizontalBar";
		}

	}
	else if ( layout == 1 ) {
		if ( chartname == "BarChartHistogram" ) {
			charttypehistogram = "bar";
		}
		else if ( chartname == "BarChartAnswers" ) {
			charttypeanswers = "bar";
		}
		else if ( chartname == "BarChartTopBlocked" ) {
			charttypetopblocked = "bar";
		}
		else if ( chartname == "BarChartTopReplies" ) {
			charttypetopreplies = "bar";
		}

	}
	else if ( layout == 2 ) {
		if ( chartname == "BarChartHistogram" ) {
			charttypehistogram = "pie";
		}
		else if ( chartname == "BarChartAnswers" ) {
			charttypeanswers = "pie";
		}
		else if ( chartname == "BarChartTopBlocked" ) {
			charttypetopblocked = "pie";
		}
		else if ( chartname == "BarChartTopReplies" ) {
			charttypetopreplies = "pie";
		}

	}
	cookie.set(cookiename, layout, 31);
	if ( chartname == "BarChartHistogram" ) {
		Draw_Bar_Chart(barLabelsHistogram, barDataHistogram, "ChartHistogram", charttypehistogram, "colourhistogram");
	}
	else if ( chartname == "BarChartAnswers" ) {
		Draw_Bar_Chart(barLabelsAnswers, barDataAnswers, "ChartAnswers", charttypeanswers, "colouranswers");
	}
	else if ( chartname == "BarChartTopBlocked" ) {
		Draw_Bar_Chart(barLabelsTopBlocked, barDataTopBlocked, "ChartTopBlocked", charttypetopblocked, "colourtopblocked");
	}
	else if ( chartname == "BarChartTopReplies" ) {
		Draw_Bar_Chart(barLabelsTopReplies, barDataTopReplies, "ChartTopReplies", charttypetopreplies, "colourtopreplies");
	}

}

function showGrid(e,axis) {
	if (e == null) {
		return true;
	}
	else if (e == "pie") {
		return false;
	}
	else {
		return true;
	}
}
function showAxis(e,axis) {
	if (e == "bar" && axis == "x") {
		return false;
	}
	else {
		if (e == null) {
			return true;
		}
		else if (e == "pie") {
			return false;
		}
		else {
			return true;
		}
	}
}

function getRandomColor() {
	var r = Math.floor(Math.random() * 255);
	var g = Math.floor(Math.random() * 255);
	var b = Math.floor(Math.random() * 255);
	return "rgba(" + r + "," + g + "," + b + ", 1)";
}
function poolColors(a) {
	var pool = [];
	for(i = 0; i < a; i++) {
		pool.push(getRandomColor());
	}
	return pool;
}
function getChartType(e) {
	if (e == null) {
		return 'horizontalBar';
	}
	else {
		return e;
	}
}


function getSDev(datasetname){
	var avg = getAvg(datasetname);
	
	var squareDiffs = datasetname.map(function(value){
		var diff = value - avg;
		var sqrDiff = diff * diff;
		return sqrDiff;
	});
	
	var avgSquareDiff = getAvg(squareDiffs);
	var stdDev = Math.sqrt(avgSquareDiff);
	return stdDev;
}
function getMax(datasetname) {
	max = Math.max(...datasetname);
	return max + (max*0.1);
}
function getAvg(datasetname) {
	var sum, avg = 0;
	
	if (datasetname.length) {
		sum = datasetname.reduce(function(a, b) { return a*1 + b*1; });
		avg = sum / datasetname.length;
	}
	
	return avg;
}

function ZoomPanEnabled(charttype) {
	if (charttype == "bar") {
		return 'y';
	}
	else if (charttype == "horizontalBar") {
		return 'x';
	}
}
function ZoomPanMax(charttype, axis, datasetname) {
	if (axis == "x") {
		if (charttype == "bar") {
			return null;
		}
		else if (charttype == "horizontalBar") {
			return getMax(datasetname);
		}
	}
	else if (axis == "y") {
		if (charttype == "bar") {
			return getMax(datasetname);
		}
		else if (charttype == "horizontalBar") {
			return null;
		}
	}
}

</script>
</head>
<body onload="initial();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="about:blank" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="action_script" value="start_suricata_stats.sh">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_wait" value="5">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="SystemCmd" value="">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<input type="hidden" name="amng_custom" id="amng_custom" value="">
<table class="content" align="center" cellpadding="0" cellspacing="0">
<tr>
<td width="17">&nbsp;</td>
<td valign="top" width="202">
<div id="mainMenu"></div>
<div id="subMenu"></div></td>
<td valign="top">
<div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
<tr>
<td valign="top">
<table width="760px" border="0" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
<tbody>
<tr bgcolor="#4D595D">
<td valign="top">
<div style="line-height:10px;">&nbsp;</div>
<div class="formfonttitle" id="suricatastatstitle">Suricata Statistics</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;">
<tr class="apply_gen" valign="top" height="35px">
<td style="background-color:rgb(77, 89, 93);border:0px;">
<input type="button" onclick="applyRule();" value="Update stats" class="button_gen" name="button">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="button" onclick="ToggleLines();" value="Toggle Lines" class="button_gen" name="button">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="button" onclick="ToggleFill();" value="Toggle Fill" class="button_gen" name="button">
</td>
</tr>
</table>


<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible" id="last30">
<tr>
<td colspan="2">Threats Detected Last 30 days (click to expand/collapse)</td>
</tr>
</thead>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="divLineChartThreatsMonthly" height="300" /></div>
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>

<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible expanded">
<tr><td colspan="2">Threats Detected Last 30 days (click to expand/collapse) - limited to 250</td></tr>
</thead>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable StatsTable">
	<col style="width:60px;">
	<col style="width:80px;">
	<col style="width:240px;">
	<col style="width:100px;">
	<col style="width:60px;">
	<col style="width:90px;">
	<col style="width:90px;">
	<col style="width:50px;">
	<thead>
	<tr>
	<th class="keystatsnumber">Date</th>
	<th class="keystatsnumber">ID</th>
	<th class="keystatsnumber">Description</th>
	<th class="keystatsnumber">Classification</th>
	<th class="keystatsnumber">Priority</th>
	<th class="keystatsnumber">Source IP</th>
	<th class="keystatsnumber">Destintation IP</th>
	<th class="keystatsnumber">Count</th>
	</tr>
	</thead>

	<tr id="DatadivTableThreats" />	
</table>
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>

</td>
</tr>
</tbody>
</table></td>
</tr>
</table>
</td>
</tr>
</table>
</form>
<div id="footer">
</div>
</body>
</html>
