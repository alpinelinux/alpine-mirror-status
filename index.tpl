<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mirror health</title>
    <link rel="stylesheet" href="https://unpkg.com/purecss@1.0.0/build/pure-min.css">    <!--[if lte IE 8]>
        <link rel="stylesheet" href="https://unpkg.com/purecss@1.0.0/build/grids-responsive-old-ie-min.css">
    <![endif]-->
    <!--[if gt IE 8]><!-->
        <link rel="stylesheet" href="https://unpkg.com/purecss@1.0.0/build/grids-responsive-min.css">
    <!--<![endif]-->
	<style>
	html, body {
		margin: 0;
		padding: 0;
		height: 100%;
		font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial,
			sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
		color: #526066;
		font-size: 1.0em;
	}
	div#wrapper {
		min-height: 100%;
		position: relative;
	}
	header {
		border-bottom: 1px solid #eaecef;
	}
	.logo {
	    padding:1em;
	}
	#content {
	    margin: 0 auto;
	    padding: 0em 1em 2em 1em;
	    max-width: 1080px;
	    padding-bottom: 1em;
	    padding-top: 2em;
	}
	footer {
	    background: #111;
	    color: #888;
	    text-align: center;
	    position: absolute;
	    bottom: 0;
	    width: 100%;
	    padding-top: 0.5em;
	    padding-bottom: 0.5em;
	    font-size: 0.8em;
	}
	.last-updated {
		color: #ccc;
		margin: 1em;
		margin-bottom: 2em;
	}
	.mirror-meta {
		margin: 1em;
		margin-left: 0;
	}
	.status-ok {
		color: #228B22;
		font-weight: bold;
	}
	.status-na {
		color: #ccc;
	}
	.status-warn {
		color: #DAA520;
		font-weight: bold;
	}
	.status-error, .status-unk {
		color: #8B0000;
		font-weight: bold;
	}
	.mirrors table, .status table {
		width: 100%;
	}
	</style>
</head>

<body>
	<div id="wrapper">
		<header class="pure-g">
			<div class="pure-u-1 pure-u-lg-4-24">
				<div class="logo">
					<a href="/"><img src="https://alpinelinux.org/alpinelinux-logo.svg" alt="Alpine Logo" class="pure-img"></a>
				</div>
			</div>
		</header>
		<div id="content">
			<div class="pure-g mirrors">
				<div class="pure-u-1">
					<h1>Official Alpine Linux mirrors</h1>
					<table class="pure-table pure-table-striped">
						<thead>
							<tr>
								<th>Mirror name</th>
								<th>Service urls</th>
								<th>Location</th>
								<th>Bandwidth</th>
								<th>Status</th>
							</tr>
						</thead>
						<tbody>
							{{#mirrors}}
							<tr>
								<td>{{name}}</td>
								<td>
									{{#urls}}
									<a href="{{url}}">{{scheme}}</a>
									{{/urls}}
								</td>
								<td>
									<span>{{location}}</span>
								</td>
								<td>
									<span>{{bandwidth}}</span>
								</td>
								<td>
									<a href="#mirror{{num}}">Status</a>
								</td>
							</tr>
							{{/mirrors}}
						</tbody>
					</table>
				</div>
			</div>
			<div class="pure-g status">
				<div class="pure-u-1">
					<h1>Status of Alpine Linux mirrors</h1>
					<p>The status of each mirrors apkindex is checked via http
					"Last modified" header tag which is compared with the master
					mirror. If the apkindex is found the difference is displayed in
					the table. If the date of the index is the same (or less than one hour)
					the status will be displayed as OK. If an http error code is
					returned it will be displayed in the table instead.</p>
					{{#status}}
					<h2 id="mirror{{num}}">{{url}}	</h2>
					<div class="mirror-meta">
						<ul class="mirror-meta">
							<li>Generated in {{duration}} seconds.</li>
							<li>Found {{count}} indexes.</li>
						</ul>
					</div>
					<table class="pure-table pure-table-striped">
						<thead>
							<tr>
								{{#thead}}
								<th>{{.}}</th>
								{{/thead}}
							</tr>
						</thead>
						<tbody>
							{{#tbody}}
							<tr>
								{{#row}}
								<td class="{{class}}">{{text}}</td>
								{{/row}}
							</tr>
							{{/tbody}}
						</tbody>
					</table>
					{{/status}}
				</div>
			</div>
			<div class="last-updated">Last updated: <span>{{last_update}}</span> UTC</div>
		</div>
		<footer>© Copyright 2017 Alpine Linux Development Team all rights reserved</footer>
	</div>
</body>
</html>