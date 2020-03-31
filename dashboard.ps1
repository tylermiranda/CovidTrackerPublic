Import-Module "$PSScriptRoot\UniversalDashboard.psd1" 
$Root = $PSScriptRoot
#$theme = . (Join-Path $Root "Theme.ps1")
$Theme = New-UDTheme -Name "Basic" -Definition @{
    '.modal'                         = @{
        'max-height' = '90%'
        'bottom'     = '10%'
    }
    '.modal .modal-footer'           = @{
        'height' = '100px'
    }
    '.modal .modal-footer .btn'      = @{
        'margin' = '15px 0'
    }
    '.btn, .btn-large, .btn-small'   = @{
        'background-color' = '#435ce8'
    }
    '.row .col.s11'                  = @{
        'margin-top' = '25px'
    }
    'nav'                            = @{
        'background-color' = '#3f51b5'
        
    }
    '.sidenav'                       = @{
        'background-color' = '#3f51b5'
    }
    '.sidenav li>a'                  = @{
        'color' = '#FFFFFF'
    }
    '.divider'                       = @{
        'background-color' = '#3f51b5'
    }
    '.page-footer'                   = @{
        'background-color' = '#3f51b5'
    }
    '.page-footer .footer-copyright' = @{
        'background-color' = '#3f51b5'
    }


}
#$Theme = Get-UDTheme -Name Default
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'
(New-Object System.Net.WebClient).DownloadFile('https://covidtracking.com/api/us/daily.csv', 'usdaily.csv')
(New-Object System.Net.WebClient).DownloadFile('https://covidtracking.com/api/us.csv', 'current.csv')
(New-Object System.Net.WebClient).DownloadFile('https://covidtracking.com/api/states.csv', 'statescurrent.csv')
(New-Object System.Net.WebClient).DownloadFile('https://covidtracking.com/api/states/daily.csv', 'statesdaily.csv')

$Global:infectiondata = Import-Csv -Path 'usdaily.csv' | ForEach-Object {
    [PSCustomObject]@{
        'date'          = $_.date
        'total'         = $_.totalTestResults
        'positive'      = $_.positive
        'negative'      = $_.negative
        'infectionrate' = [math]::Round([int]$_.positive / ([int]$_.positive + [int]$_.negative) * 100, 2)
    }
}
$Global:stateinfectiondata = Import-Csv -Path 'statesdaily.csv' | ForEach-Object {
    [PSCustomObject]@{
        'date'          = $_.date
        'state'         = $_.state
        'total'         = $_.totalTestResults
        'positive'      = $_.positive
        'negative'      = $_.negative
        'infectionrate' = if ($_.negative -gt 0) { [math]::Round([int]$_.positive / ([int]$_.positive + [int]$_.negative) * 100, 2) } else { "NA" }
    }
}
$Cache:StateCaseCount = Invoke-RestMethod -Uri 'https://corona.lmao.ninja/states'
$Cache:USAHistoricalCaseCount = Invoke-RestMethod -Uri 'https://corona.lmao.ninja/v2/historical/US'
$Cache:USTotalCountsToday = Invoke-RestMethod -Uri 'https://corona.lmao.ninja/countries/us'
$Cache:statesdaily = Import-Csv -Path "statesdaily.csv"
$Cache:statescurrent = Import-Csv -Path "statescurrent.csv"
$Cache:UScurrent = Import-Csv -Path "current.csv"

#>

$SessionsSchedule = New-UDEndpointSchedule -Every 30 -Minute
$SessionsEndpoint = New-UDEndpoint -Schedule $SessionsSchedule -Endpoint {
    [Net.ServicePointManager]::SecurityProtocol = 'Tls12'
    (New-Object System.Net.WebClient).DownloadFile('https://covidtracking.com/api/us/daily.csv', 'usdaily.csv')
    (New-Object System.Net.WebClient).DownloadFile('https://covidtracking.com/api/us.csv', 'current.csv')
    (New-Object System.Net.WebClient).DownloadFile('https://covidtracking.com/api/states.csv', 'statescurrent.csv')
    (New-Object System.Net.WebClient).DownloadFile('https://covidtracking.com/api/states/daily.csv', 'statesdaily.csv')

    $Cache:StateCaseCount = Invoke-RestMethod -Uri 'https://corona.lmao.ninja/states'
    $Cache:USAHistoricalCaseCount = Invoke-RestMethod -Uri 'https://corona.lmao.ninja/v2/historical/US'
    $Cache:USTotalCountsToday = Invoke-RestMethod -Uri 'https://corona.lmao.ninja/countries/us'
    $Cache:statesdaily = Import-Csv -Path "statesdaily.csv"
    $Cache:statescurrent = Import-Csv -Path "statescurrent.csv"
    $Cache:UScurrent = Import-Csv -Path "current.csv"
}
$Page1 = New-UDPage -Name "US COVID-19 Testing Tracker" -Title 'US COVID-19 Testing Tracker' -Content {  

    New-UdRow {
        New-UDColumn -Size 12 {
            New-UDHTML -Markup "<p><b>Huge Update</b> * A lot of new data has been added to the State Data page for each state. Click on the <i>Additional Data</i> button on each state.<p>"
            New-UDLink -Text "Click Here for Additional State Data" -Url "https://covidtracking.azurewebsites.net/States-Data" -FontColor blue
            New-UDHTML -Markup "<p>Tracking COVID-19 in the US through testing data. All data is sourced from The COVID Tracking Project. This site is not affiliated with The COVID Tracking Project. This site aims to track testing for COVID-19 in the US. It will not track recoveries.<p>"
        }
    }
    New-UDRow {
        New-UDColumn -Size 6 {
            New-UDChart -Title "US Total Tests by Date" -Type Line -AutoRefresh -RefreshInterval 240 -Endpoint {
                $USDailyCounts = Import-Csv -Path "usdaily.csv"
                $USDailyCounts | sort date | Out-UDChartData  -LabelProperty "date" -Dataset @(
                    New-UDChartDataset -DataProperty 'total' -Label "Total Tests" 
                    New-UDChartDataset -DataProperty 'positive' -Label "Positive Tests" -BackgroundColor red
                    New-UDChartDataset -DataProperty 'pending' -Label "Pending Tests" -BackgroundColor blue
                    New-UDChartDataset -DataProperty 'hospitalized' -Label "Hospitalized" -BackgroundColor orange
                )
            } 
            New-UDParagraph -Content {
                "* This chart is updated with a data snapshot that is taken at 4pm EST and may vary from numbers displayed on the right."
            }
            New-UDHTML -Markup "<p>** Hospitalization data is <b>very incomplete</b> so far. Many states are not reporting this data. To see the ones that are, see the State Data page.</p>"
            
            
        }
        New-UDRow {
            New-UDColumn -Size 6 {
                New-UDCounter -Title "US Total Tests To Date" -RefreshInterval 240 -AutoRefresh -Endpoint {
                    $AllTests = Import-Csv -Path "current.csv"
                    $Count = $AllTests.totalTestResults   
                    $Count
                } -TextSize Medium
                New-UdCounter -Title "US Total Positive Tests To Date" -RefreshInterval 240 -Autorefresh -Endpoint {
                    $allstatespos = Import-Csv -Path 'current.csv'
                    $pos = [int]$allstatespos.positive
                    $pos
                } -Textsize Medium 
                New-UdCounter -Title "% Positive vs Tested To Date" -RefreshInterval 240 -Autorefresh -Endpoint {
                    $allstatespercent = Import-Csv -Path 'current.csv'
                    $percent = [int]$allstatespercent.positive / ([int]$allstatespercent.positive + [int]$allstatespercent.negative) * 100
                    $percent
                } -Textsize Medium -Format '0.00'
                New-UDCounter -Title "US Total Hospitalizations" -RefreshInterval 240 -AutoRefresh -Endpoint {
                    $Count = $Cache:UScurrent.hospitalized   
                    $Count
                } -TextSize Medium
            }
        }

    }
    New-UDRow {
        New-UDColumn -size 12 {
            New-UDLink -Text "Click Here for Additional State Data" -Url "https://covidtracking.azurewebsites.net/States-Data" -FontColor blue
        }
    }
}

$Page2 = New-UDPage -Name "States Data" -Title "States Data" -Content {
    New-UDRow {
        New-UDColumn -Size 9 {
            New-UDParagraph -Content {
                "*Not all states are reporting hospitalization data. Kudos to the ones that are. Not all states report negative and pending tests."
            }
            New-UDChart -Title "Tests by State" -Type Bar -Width '100%' -AutoRefresh -Endpoint {
                $StateCounts = Import-Csv -Path "statescurrent.csv"
                $StateCounts | Out-UDChartData -LabelProperty "state" -Dataset @(
                    New-UDChartDataset -DataProperty 'hospitalized' -Label "Hospitalized" -BackgroundColor orange
                    New-UDChartDataset -DataProperty 'positive' -Label "Positive Tests" -BackgroundColor red
                    New-UDChartDataset -DataProperty 'totalTestResults' -Label "Total Tests"
                    New-UDChartDataset -DataProperty 'pending' -Label "Pending Tests" -BackgroundColor blue
                        
                    
                )
            } -Labels @("states") -Options @{
                scales = @{
                    xAxes = @(
                        @{
                            stacked = $true
                        }
                    )
                    yAxes = @(
                        @{
                            stacked = $false
                        }
                    )
                }
            }

        }
    }

    New-UDRow {
        New-UDHtml -Markup "<i>*0 could mean that the state isn't reporting data for this datapoint or it could also mean zero.</i>"
        New-UdGrid -Title "US States & Territories Data" -DefaultSortColumn 'Total Tests' -FilterText "Search or Filter by State" -DefaultSortDescending -NoPaging -Endpoint {
            $Cache:statescurrent | Where { $_.negative -ne $null -and $_.negative -ne "" } | ForEach-Object {
                [PSCustomObject]@{
                    'State'                         = $_.state
                    'Positive Tests'                = [int]$_.positive
                    'Negative Tests'                = [int]$_.negative
                    'Pending'                       = [int]$_.Pending
                    'Total Tests'                   = [int]$_.totalTestResults
                    'Hospitalizations'              = [int]$_.hospitalized #if ([int]$_.hospitalized -eq 0 -or [int]$_.hospitalized -eq $null){"Not Reporting"}else{[int]$_.hospitalized}
                    #'Hospitalized Increase'         = [int]$_.hospitalizedIncrease
                    '% Positive (Excludes Pending)' = [math]::Round([int]$_.positive / ([int]$_.positive + [int]$_.negative) * 100, 1)
                    ' '                             = New-UDButton -Text "Additional $($_.state) Data..." -OnClick (New-UDEndpoint -Endpoint { 
                            Show-UDModal -Header {
                                New-UDHeading -Size 5 -Text "$($_.state) State - Additional Information"
                            } -Footer {
                                New-UDRow {
                                    New-UDColumn -Size 1 {
                                        New-UDButton -Text "Close" -OnClick {
                                            Hide-UDModal
                                        }
                                    }
                                    New-UDColumn -Size 11 {
                                        New-UDLink -Text "Last Checked: $($_.datechecked)" -Url "https://covidtracking.com/data/#$($_.state)" -OpenInNewWindow
                                    }
                                }
                                    
                            } -Content {
                                <#
                                    New-UDTable -Title "Modules" -Headers @("Name", "Path") -Content {
                                        $ArgumentList[0] | Out-UDTableData -Property @("ModuleName", "FileName")
                                    }#>
                                #New-UDHtml -Markup "<h5>$($_.state)</h5>"
                                New-UDRow {
                                    New-UDParagraph -Content { "* Not all states report pending tests" } 
                                    New-UDHTML -Markup "<i>The chart below tracks the cumulative of each test result by date."
                                    New-UDColumn -size 6 {
                                        New-UDChart -Title "$($_.state) State Total Tests Over Time" -Type Line -Height '400px' -Width '90%' -AutoRefresh -RefreshInterval 60 -Endpoint {
                                            $statesdaily = Import-Csv -Path "statesdaily.csv"
                                            $statesdaily | sort date | Where-Object -Property 'state' -eq $_.state | Out-UDChartData -LabelProperty "date" -Dataset @(
                                                New-UDChartDataset -DataProperty 'total' -Label "Total Tests" 
                                                New-UDChartDataset -DataProperty 'positive' -Label "Positive Tests" -BackgroundColor red
                                                New-UDChartDataset -DataProperty 'pending' -Label "Pending Tests" -BackgroundColor purple
                                                New-UDChartDataset -DataProperty 'hospitalized' -Label "Hospitalized" -BackgroundColor orange
                                            )
                                        } 
                                        New-UDHTML -Markup "<i>The chart below tracks the new tests of each type per day. Ideally we want to see red(positive tests) go down and green(negative tests) go up but red may increase as blue(total tests) increases."
                                        New-UDChart -Title "Tracking $($_.state) State New Daily Test Counts" -Type bar -Height '400px' -Width '90%' -AutoRefresh -RefreshInterval 60 -Endpoint {
                                            $Cache:statesdaily | sort date | Where-Object -Property "State" -eq $_.state | Out-UDChartData  -LabelProperty "date" -Dataset @(
                                                New-UDChartDataset -DataProperty 'positiveIncrease' -Label "New Positives" -BackgroundColor red
                                                New-UDChartDataset -DataProperty 'negativeIncrease' -Label "Negatives Increase" -BackgroundColor '#c2f00c'                                                       
                                                New-UDChartDataset -DataProperty 'totalTestResultsIncrease' -Label "Tests Increase" -BackgroundColor '#3492eb'
                                                New-UDChartDataset -DataProperty 'deathIncrease' -Label "New Deaths" -BackgroundColor black
                                                        
                                                        
                                            )
                                        } <#-Labels @("states") -Options @{
                                                    scales = @{
                                                        xAxes = @(
                                                            @{
                                                                stacked = $true
                                                            }
                                                        )
                                                        yAxes = @(
                                                            @{
                                                                stacked = $false
                                                            }
                                                        )
                                                    }
                                                }#>

                                        New-UDHTML -Markup "<br><br><br>"
                                        New-UDHTML -Markup "<i>The chart below tracks the percentage of tests over time that were positive for COVID-19."

                                        New-UDChart -Title "Tracking $($_.state) State Positive Test Rate(%) Over Time" -Type bar -Height '400px' -Width '90%' -AutoRefresh -RefreshInterval 60 -Endpoint {
                                            $Global:stateinfectiondata | sort date | Where-Object -Property "State" -eq $_.state | Out-UDChartData  -LabelProperty "date" -Dataset @(
                                                New-UDChartDataset -DataProperty 'infectionrate' -Label "Positive Test Rate %" -BackgroundColor red
                                            )
                                        }
                                        if ($_.hospitalized -gt 1) {
                                            New-UDHTML -Markup "<i>The chart below tracks the number of hospitalizations for the state of $($_.state) over time."
                                            New-UDChart -Title "Tracking $($_.state) State Hospitalizations By Date" -Type bar -Height '400px' -Width '90%' -AutoRefresh -RefreshInterval 60 -Endpoint {
                                                $Cache:statesdaily | sort date | Where-Object -Property "State" -eq $_.state | Out-UDChartData  -LabelProperty "date" -Dataset @(
                                                    New-UDChartDataset -DataProperty 'hospitalized' -Label "Total Hospitalizations" -BackgroundColor '#f7ba00'
                                                    New-UDChartDataset -DataProperty 'hospitalizedIncrease' -Label "New Hospitalizations" -BackgroundColor '#f77700'
                                                        
                                                )
                                            }  
                                        }


                                        <# charted over 
                                            New-UDChart -Title "Tracking $($_.state) State Positive Test Rate(%) By Date" -Type bar -Height '400px' -Width '90%' -AutoRefresh -RefreshInterval 60 -Endpoint {
                                                $Global:stateinfectiondata | sort date | Where-Object -Property "State" -eq $_.state | Out-UDChartData  -LabelProperty "date" -Dataset @(
                                                    $Dataset1 = New-UDChartDataset -DataProperty 'infectionrate' -Label "Positive Test Rate %" -BackgroundColor '#eb5b34'
                                                    $Dataset1.type = 'line'
                                                    $Dataset2 = New-UDChartDataset -DataProperty 'positive' -Label "Positive Test Count" -BackgroundColor 'red'
                                                    $Dataset2.type = 'bar'
                                                    $Dataset1
                                                    $Dataset2
                                                    
                                                )
                                            }#>
                                        <# Future addition daily new positives 
                                            New-UDChart -Title "Tracking $($_.state) State Positive Cases By Date" -Type bar -Height '400px' -Width '90%' -AutoRefresh -RefreshInterval 60 -Endpoint {
                                                $Global:stateinfectiondata | sort date | Where-Object -Property "State" -eq $_.state | Out-UDChartData  -LabelProperty "date" -Dataset @(
                                                    New-UDChartDataset -DataProperty 'positive' -Label "Positive Count" -BackgroundColor '#eb5b34'
                                                )
                                            } #>
                                            
                                    }
                                    New-UDColumn -Size 6 {
                                        New-UdGrid -Title "$($_.state) State Daily Datapoints" -NoPaging -NoFilter -Endpoint {
                                            $Cache:statesdaily | Where-Object -Property "state" -eq "$($_.state)" | ForEach-Object {
                                                [PSCustomObject]@{
                                                    'Date'                 = [string]$_.date
                                                    'Total Positive'       = [int]$_.positive
                                                    'New Positive'         = [int]$_.positiveIncrease
                                                    'Total Negative'       = [int]$_.negative
                                                    'New Negative'         = [int]$_.negativeIncrease
                                                    'Total Pending'        = [int]$_.pending
                                                    'Total Hospitalized'   = if ($_.hospitalized -gt 0) { [int]$_.hospitalized } else { "NA" }
                                                    'New Hospitalizations' = if ($_.hospitalized -gt 0) { [int]$_.hospitalizedIncrease } else { "NA" }
                                                    'Total Deaths'         = [int]$_.death
                                                    'New Deaths'           = [int]$_.deathIncrease
                                                        
                                                }
                                            } | Out-UDGridData
                                        } 
                                    }
                                }

                                    

                            } -Width '95%' -Height '90%' -FixedFooter
                        }) #-ArgumentList $_.Modules)
                    #'Hospitalization %'             = if ($_.hospitalization -ne "0") {[math]::Round([int]$_.hospitalization / ([int]$_.positivee) * 100, 1)} else { $_.hospitalization = 0 }
                }
            } | Out-UDGridData
        }
        
    }

}
$Page3 = New-UDPage -Name "Credits" -Title "Credits" -Content {
    New-UDRow {
        New-UDColumn {
            New-UDHtml -Markup "
            <p> The <a href='https://covidtracking.com/' target='_blank'><u>COVID Tracking Project</u></a> for providing the API and the data. </p>
            <p> Adam Driscoll and Ironman Software for the dashboard framework, <a href='https://ironmansoftware.com/powershell-universal-dashboard/' target='_blank'><u>Universal Dashboard</u></a>.</p>
            <p> <a href='https://icons8.com/license' target='_blank'><u>icons8</u></a> for icons on this site.
            "
        }

    }

}
$Page4 = New-UDPage -Name "About This Project/Me" -Title "About This Project/Me" -Content {
    New-UDRow {
        New-UDColumn -size 6 {
            New-UDImage -Path $Root\me.png
            New-UDHtml -Markup "
            <a href='https://twitter.com/tylermiranda?ref_src=twsrc%5Etfw' class='twitter-follow-button' data-show-count='false' target='_blank'><u>Follow @tylermiranda</u></a><script async src='https://platform.twitter.com/widgets.js' charset='utf-8'></script>
            <p> For the past several weeks as this pandemic has escalated here in the US, I often wanted to know how well we were testing as it was quite evident that the US didn't start testng
            early or soon enough and only recently remedied that somewhat. As a large and populous country I thought it was important to be able to understand what percentage of the tests that were being
            conducted were positive.  In addition, comparing different states.  I found The COVID Tracking Project through Twitter and found that they have done a great job compiling the available data
            but I didn't see it visualized in the way I wanted it.  I decided that maybe I could contribute a bit by creating this site and visualizing that data in a way that maybe tells a story.
            This is one of the ways I'm trying to give back and help support my fellow citizens in this trying time.  <br>
            
            -Tyler Miranda</p>"
        }

    }

}
$Page5 = New-UDPage -Name "Updates" -Title "Updates" -Content {
    New-UDRow {
        New-UDColumn -size 6 {
            New-UDHTML -Markup "
                <b>3/29/2020</b><br>
                -Changed the sidebar nav top spacing<br>
                -created new custom theme<br>"
            New-UDHTML -Markup "
                <b>3/27/2020</b><br>
                -Hospitalization Data on States Page<br>"
            New-UDHTML -Markup "
                <b>3/24/2020</b><br>
                -Added additional chart in state data modal.<br>
                -cleaned up some formatting.<br>
                -Added link to source data in state modal.<br>
                -Added pending cases on main page chart.<br>"
            New-UDHTML -Markup "
                <b>3/23/2020</b><br>
                -Fix for change in data causing line chart to display backwards<br>
                -Added button for displaying specific state data on States page<br>"
            New-UDHTML -Markup "
                <b>3/22/2020</b><br>
                -Added page and chart for charting infection rate by date<br>
                -Added text explaining data<br>
                -Added hospitalization visuals<br>"
            New-UDHTML -Markup "
                <b>3/21/2020</b><br>
                -Fixed issue on front page with stacked bar graph<br>"
            New-UDHTML -Markup "
                <b>3/21/2020</b><br>
                -Site Launch<br>"

        }

    }

}
$Page6 = New-UDPage -Name "Useful Links" -Title "Useful Links" -Content {
    New-UDRow {
        New-UDColumn -size 6 {
            New-UDRow {
                New-UDLink -Text "The COVID Tracking Project" -Url "https://covidtracking.com" -OpenInNewWindow
            }
            New-UDRow {
                New-UDLink -Text "COVID19INFO.LIVE" -Url "https://covid19info.live" -OpenInNewWindow
            }
            New-UDRow {
                New-UDLink -Text "John Hopkins Dashboard" -Url "https://gisanddata.maps.arcgis.com/apps/opsdashboard/index.html#/bda7594740fd40299423467b48e9ecf6" -OpenInNewWindow
            }
            New-UDRow {
                New-UDLink -Text "Worldometers Coroanvirus" -Url "https://www.worldometers.info/coronavirus" -OpenInNewWindow
            }
            New-UDRow {
                New-UDLink -Text "IHME US Projections" -Url "https://covid19.healthdata.org/projections" -OpenInNewWindow
            }
        }

    }
}
$Page7 = New-UDPage -Name "Tracking US Infection Rate" -Title "Tracking US Infection Rate" -Content {
    New-UDRow {
        New-UDColumn -size 10 {
            New-UDChart -Title "Tracking US Positive Test Rate(%) By Date" -Type bar -AutoRefresh -RefreshInterval 60 -Endpoint {
                $Global:infectiondata | sort date | Out-UDChartData  -LabelProperty "date" -Dataset @(
                    New-UDChartDataset -DataProperty 'infectionrate' -Label "Positive Test Rate %" -BackgroundColor red
                )
            } 
            New-UDParagraph -Content {
                "This chart tracks the percentage of tests performed on that day that were positive for COVID-19."
            }
        }
    }
}
<# not used
$Page8 = New-UDPage -Name "State Detail" -Content {
    $statecurrent = Import-Csv -Path "statescurrent.csv"
    New-UDRow {
        New-UDColumn -size 12 {
            New-UDSelect -Label "State" -Icons maps -Option {
                $statecurrent | ForEach-Object {
                    New-UDSelectOption -Name $_.state -Value $_.state
                }
            } -OnChange {
                $Session:State = $EventData
            }
        }
    }
}
$Page9 = New-UDPage -Name "State Case Data" -Content {
    $statecurrent = Import-Csv -Path "statescurrent.csv"
    New-UDRow {
        New-UdGrid -Title "State Case Data" -DefaultSortColumn 'Total Cases' -FilterText "Search or Filter by State" -DefaultSortDescending -NoPaging -Endpoint {
            $Cache:StateCaseCount | ForEach-Object {
                [PSCustomObject]@{
                    'State'        = $_.state
                    'Total Cases'  = [int]$_.cases
                    'Today Cases'  = [int]$_.todayCases
                    'Deaths'       = [int]$_.deaths
                    'Today Deaths' = [int]$_.todayDeaths
                    'Active Cases' = [int]$_.active
                }
            } | Out-UDGridData
        }
        
    }
}
#>
$Page10 = New-UDPage -Name "US Case Overview" -Title "US Case Overview" -Content {
    New-UDRow {
        New-UDColumn -Size 8 {
            New-UDChart -Title "US Confirmed Cases by Date" -Type bar -AutoRefresh -RefreshInterval 240 -Endpoint {
                $cases = $Cache:USAHistoricalCaseCount
                $counts = $cases.timeline.cases
                $array = $counts.PsObject.Properties | foreach { @{Name = $_.Name; Value = $_.Value } }
                $array | Out-UDChartData  -LabelProperty "Name" -Dataset @(
                    New-UDChartDataset -DataProperty "Value" -Label "Total Cases" -BackgroundColor Red
                )
            } 
            New-UDChart -Title "US Confirmed Deaths by Date" -Type bar -AutoRefresh -RefreshInterval 240 -Endpoint {
                $deaths = $Cache:USAHistoricalCaseCount
                $counts = $deaths.timeline.deaths
                $array = $counts.PsObject.Properties | foreach { @{Name = $_.Name; Value = $_.Value } }
                $array | Out-UDChartData  -LabelProperty "Name" -Dataset @(
                    New-UDChartDataset -DataProperty "Value" -Label "Total Deaths" -BackgroundColor Black
                )
            }
        }
        New-UDColumn -Size 4 {
            New-UDCounter -Title "US New Confirmed Cases Today" -RefreshInterval 240 -AutoRefresh -Endpoint {
                $newcases = $Cache:USTotalCountsToday
                $counts = $newcases.todayCases
                $counts
            } -TextSize Medium
            New-UDCounter -Title "US Total Confirmed Cases" -RefreshInterval 240 -AutoRefresh -Endpoint {
                $totalcases = $Cache:USTotalCountsToday
                $counts = $totalcases.cases
                $counts
            } -TextSize Medium
            New-UDCounter -Title "US New Deaths Today" -RefreshInterval 240 -AutoRefresh -Endpoint {
                $todaydeaths = $Cache:USTotalCountsToday
                $counts = $todaydeaths.todayDeaths
                $counts
            } -TextSize Medium
            New-UDCounter -Title "US Total Deaths" -RefreshInterval 240 -AutoRefresh -Endpoint {
                $totaldeaths = $Cache:USTotalCountsToday
                $counts = $totaldeaths.deaths
                $counts
            } -TextSize Medium
        }
    }
}


### Sidebar Navigation Section ###
$Navigation = New-UDSideNav -Width 300 -Content {
    #$states = Import-Csv -Path "statescurrent.csv" #| Where { $_.negative -ne $null -and $_.negative -ne "" } | ForEach-Object
    New-UDSideNavItem -Divider
    New-UDSideNavItem -Divider
    New-UDSideNavItem -Divider
    New-UDSideNavItem -Divider
    New-UDSideNavItem -Divider
    New-UDSideNavItem -Divider
    
    New-UDSideNavItem -Text "US Testing Overview" -PageName "US COVID-19 Testing Tracker" -Icon medkit
    New-UDSideNavItem -Divider

    New-UDSideNavItem -Text "US Case Overview" -PageName "US Case Overview" -Icon medkit
    New-UDSideNavItem -Divider

    New-UDSideNavItem -Text "Tracking US Positive Rate" -PageName "Tracking US Infection Rate" -Icon stethoscope
    New-UDSideNavItem -Divider
    
    New-UDSideNavItem -Text "State Test Data" -PageName "States Data" -Icon map
    New-UDSideNavItem -Divider
    <# Taking Out for now
    New-UDSideNavItem -Text "State Case Data" -PageName "State Case Data" -Icon map
    New-UDSideNavItem -Divider
    #>
    <# This section is not ready yet
    New-UDSideNavItem -Text "State Detail" -PageName "State Detail" -Icon flag
    New-UDSideNavItem -Divider
    #>

    New-UDSideNavItem -Text "About This Project/Me" -PageName "About This Project/Me" -Icon twitter
    New-UDSideNavItem -Divider
    
    New-UDSideNavItem -Text "Credits" -PageName "Credits" -Icon book
    New-UDSideNavItem -Divider
    
    New-UDSideNavItem -Text "Updates" -PageName "Updates" -Icon exclamation
    New-UDSideNavItem -Divider

    New-UDSideNavItem -Text "Useful Links" -PageName "Useful Links" -Icon link
    New-UDSideNavItem -Divider


} -Fixed

$Footer = New-UDFooter -Copyright "2020 Tyler Miranda - Made with Universal Dashboard - Data from The COVID Tracking Project" -Links @(
    New-UDLink -Text "Twitter | " -Url "https://twitter.com/tylermiranda"
    New-UDLink -Text "The COVID Tracking Project" -Url "https://covidtracking.com/"
)
$PublishedFolder = Publish-UDFolder -Path 'images' -RequestPath "/images"
$Dashboard = New-UDDashboard -Title "COVID-19 US Testing Data" -Pages @($Page1, $Page2, $Page3, $Page4, $Page5, $Page6, $Page7, $Page10) -Navigation $Navigation -Theme $Theme -Footer $Footer -NavBarLogo (New-UDImage -Url '/images/usa_square_48px.png' -Height 48 -Width 48)

Start-UDDashboard -Dashboard $Dashboard -Port 443 -Wait -Endpoint $SessionsEndpoint -PublishedFolder $PublishedFolder