package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

const (
	baseURL     = "http://127.0.0.1:8888/search"
	maxRetries  = 60
	retryDelay  = 500 * time.Millisecond
	httpTimeout = 5 * time.Second
)

type Result struct {
	Title   string `json:"title"`
	URL     string `json:"url"`
	Content string `json:"content"`
}

type Response struct {
	Results []Result `json:"results"`
}

func fatal(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}

// resolveTime maps human-friendly durations to the closest SearXNG time_range.
// SearXNG only supports: day, week, month, year.
func resolveTime(input string) string {
	valid := map[string]string{
		"day": "day", "d": "day", "1d": "day",
		"week": "week", "w": "week", "1w": "week",
		"month": "month", "m": "month", "1m": "month",
		"year": "year", "y": "year", "1y": "year",
	}
	if v, ok := valid[strings.ToLower(input)]; ok {
		return v
	}
	fatal("Error: invalid -t value %q (expected: d/day, w/week, m/month, y/year)", input)
	return ""
}

func main() {
	limit := flag.Int("n", 10, "max results")
	categories := flag.String("c", "", "categories: general,news,science,it,files,social media")
	timeFlag := flag.String("t", "", "time filter: d/day, w/week, m/month, y/year")
	lang := flag.String("l", "", "language code (default: auto)")
	engines := flag.String("e", "", "engines (comma-separated)")
	page := flag.Int("p", 1, "page number")
	rawJSON := flag.Bool("json", false, "raw JSON output")
	urlsOnly := flag.Bool("urls", false, "only URLs, one per line")
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: search [flags] <query>\n\nFlags:\n")
		flag.PrintDefaults()
	}
	flag.Parse()

	query := strings.Join(flag.Args(), " ")
	if query == "" {
		flag.Usage()
		os.Exit(1)
	}

	params := url.Values{}
	params.Set("q", query)
	params.Set("format", "json")
	params.Set("pageno", fmt.Sprintf("%d", *page))
	if *categories != "" {
		params.Set("categories", *categories)
	}
	if *timeFlag != "" {
		params.Set("time_range", resolveTime(*timeFlag))
	}
	if *lang != "" {
		params.Set("language", *lang)
	}
	if *engines != "" {
		params.Set("engines", *engines)
	}

	reqURL := baseURL + "?" + params.Encode()

	client := &http.Client{Timeout: httpTimeout}
	var body []byte
	for i := 0; i < maxRetries; i++ {
		resp, err := client.Get(reqURL)
		if err != nil {
			time.Sleep(retryDelay)
			continue
		}
		body, err = io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			time.Sleep(retryDelay)
			continue
		}
		if resp.StatusCode == 200 {
			break
		}
		body = nil
		time.Sleep(retryDelay)
	}

	if len(body) == 0 {
		fatal("Error: SearXNG not responding")
	}

	if *rawJSON {
		fmt.Print(string(body))
		return
	}

	var sr Response
	if err := json.Unmarshal(body, &sr); err != nil {
		fatal("Error: failed to parse response: %v", err)
	}

	results := sr.Results
	if *limit > 0 && len(results) > *limit {
		results = results[:*limit]
	}

	if len(results) == 0 {
		fmt.Fprintln(os.Stderr, "No results found.")
		os.Exit(0)
	}

	for _, r := range results {
		if *urlsOnly {
			fmt.Println(r.URL)
		} else {
			fmt.Printf("- [%s](%s): %s\n", r.Title, r.URL, strings.TrimSpace(r.Content))
		}
	}
}
