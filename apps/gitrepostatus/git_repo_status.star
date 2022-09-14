"""
Applet: Git Repo Status
Summary: Activity for Github repos
Description: Displays activity and current state of open PRs and Issues on your (public) Github repo of choice.
Author: joevgreathead
"""

load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("http.star", "http")
load("html.star", "html")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")
load("time.star", "time")
load("math.star", "math")

GITHUB = "https://github.com"
GITHUB_OAUTH = GITHUB + "/login/oauth"
GITHUB_AUTHORIZE = GITHUB_OAUTH + "/authorize"
GITHUB_ACCESS_TK = GITHUB_OAUTH + "/access_token"

GITHUB_API = "https://api.github.com"

GITHUB_REPO_STATUS_CLIENT_ID = "4952e81830103a985593"
GITHUB_REPO_STATUS_CLIENT_SECRET = secret.decrypt(
    "AV6+xWcEnEKdTfy/Baeex/PQARwAx3HlWiErq0p/3k9dfbzdlaqT9nhpp0dh6vvHGlm+5FEbZR6I6R5i0/txnRElkhaN4U5mJ+IZfaH7QQ3irNW8PZYbN0CPRMzT+br/ghF/Ac5FFXwquthtk0zuqW4Y8g0c/aEAI6nVjE+DgMQdJHA43+mlCQO5ZYiyMg=="
)

DEFAULT_USER = "joevgreathead"
DEFAULT_REPO = "tidbyt/community"

PLACEHOLDER_TEXT = "n/a"

IMAGE_PULL_REQUEST = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAAAXNSR0IArs4c6QAAAMZlWElmTU0AKgAAAAgABgESAAMAAAABAAEAAAEaAAUAAAABAAAAVgEbAAUAAAABAAAAXgEoAAMAAAABAAIAAAExAAIAAAAVAAAAZodpAAQAAAABAAAAfAAAAAAAAAEsAAAAAQAAASwAAAABUGl4ZWxtYXRvciBQcm8gMi40LjUAAAAEkAQAAgAAABQAAACyoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAKoAMABAAAAAEAAAAIAAAAADIwMjI6MDg6MTYgMjA6MzI6MzQAyvwpbQAAAAlwSFlzAAAuIwAALiMBeKU/dgAAA9lpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6ZXhpZj0iaHR0cDovL25zLmFkb2JlLmNvbS9leGlmLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iPgogICAgICAgICA8ZXhpZjpQaXhlbFlEaW1lbnNpb24+ODwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4xMDwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpYUmVzb2x1dGlvbj4zMDAwMDAwLzEwMDAwPC90aWZmOlhSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpSZXNvbHV0aW9uVW5pdD4yPC90aWZmOlJlc29sdXRpb25Vbml0PgogICAgICAgICA8dGlmZjpZUmVzb2x1dGlvbj4zMDAwMDAwLzEwMDAwPC90aWZmOllSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICAgICA8eG1wOkNyZWF0b3JUb29sPlBpeGVsbWF0b3IgUHJvIDIuNC41PC94bXA6Q3JlYXRvclRvb2w+CiAgICAgICAgIDx4bXA6Q3JlYXRlRGF0ZT4yMDIyLTA4LTE2VDIwOjMyOjM0PC94bXA6Q3JlYXRlRGF0ZT4KICAgICAgICAgPHhtcDpNZXRhZGF0YURhdGU+MjAyMi0wOC0yMVQxODozNToxMy0wNzowMDwveG1wOk1ldGFkYXRhRGF0ZT4KICAgICAgPC9yZGY6RGVzY3JpcHRpb24+CiAgIDwvcmRmOlJERj4KPC94OnhtcG1ldGE+CgJcdccAAABTSURBVBgZlY/BCgAgCEMzuvT/H1uHwFScGNGhIJ6tbWApP4d5sNyl1ByYOyoeRL3JfJhzIIwuNgmQhkEUBXMaYtaiEZ8vmlE20SWm07yYwVfBpW+w5DmdP0xoEQAAAABJRU5ErkJggg==
""")
IMAGE_ISSUE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAAAXNSR0IArs4c6QAAAMZlWElmTU0AKgAAAAgABgESAAMAAAABAAEAAAEaAAUAAAABAAAAVgEbAAUAAAABAAAAXgEoAAMAAAABAAIAAAExAAIAAAAVAAAAZodpAAQAAAABAAAAfAAAAAAAAAEsAAAAAQAAASwAAAABUGl4ZWxtYXRvciBQcm8gMi40LjUAAAAEkAQAAgAAABQAAACyoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAKoAMABAAAAAEAAAAIAAAAADIwMjI6MDg6MTYgMjA6NDM6MTUA8AbVSgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAA9lpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6ZXhpZj0iaHR0cDovL25zLmFkb2JlLmNvbS9leGlmLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iPgogICAgICAgICA8ZXhpZjpQaXhlbFlEaW1lbnNpb24+ODwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4xMDwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpYUmVzb2x1dGlvbj4zMDAwMDAwLzEwMDAwPC90aWZmOlhSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpSZXNvbHV0aW9uVW5pdD4yPC90aWZmOlJlc29sdXRpb25Vbml0PgogICAgICAgICA8dGlmZjpZUmVzb2x1dGlvbj4zMDAwMDAwLzEwMDAwPC90aWZmOllSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICAgICA8eG1wOkNyZWF0b3JUb29sPlBpeGVsbWF0b3IgUHJvIDIuNC41PC94bXA6Q3JlYXRvclRvb2w+CiAgICAgICAgIDx4bXA6Q3JlYXRlRGF0ZT4yMDIyLTA4LTE2VDIwOjQzOjE1PC94bXA6Q3JlYXRlRGF0ZT4KICAgICAgICAgPHhtcDpNZXRhZGF0YURhdGU+MjAyMi0wOC0yMVQxODozOTo0My0wNzowMDwveG1wOk1ldGFkYXRhRGF0ZT4KICAgICAgPC9yZGY6RGVzY3JpcHRpb24+CiAgIDwvcmRmOlJERj4KPC94OnhtcG1ldGE+Cgas74QAAABWSURBVBgZjY4LCoAwDEM33f0vrFiT4hsVUSyMfJqwtvZzes1FxCY98LoGnqjA0IubKVG9xUsVd0JeetBgBhFfOO8h9LjrWsxj9Zv5QcH4VqqZ5CqvmCffHx7/WeQEkQAAAABJRU5ErkJggg==
""")
IMAGE_COMMIT = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAAAXNSR0IArs4c6QAAAMZlWElmTU0AKgAAAAgABgESAAMAAAABAAEAAAEaAAUAAAABAAAAVgEbAAUAAAABAAAAXgEoAAMAAAABAAIAAAExAAIAAAAVAAAAZodpAAQAAAABAAAAfAAAAAAAAAEsAAAAAQAAASwAAAABUGl4ZWxtYXRvciBQcm8gMi40LjUAAAAEkAQAAgAAABQAAACyoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAKoAMABAAAAAEAAAAIAAAAADIwMjI6MDg6MTYgMjA6NTE6NDUAR1GXZAAAAAlwSFlzAAAuIwAALiMBeKU/dgAAA7FpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iPgogICAgICAgICA8dGlmZjpZUmVzb2x1dGlvbj4zMDAwMDAwLzEwMDAwPC90aWZmOllSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpYUmVzb2x1dGlvbj4zMDAwMDAwLzEwMDAwPC90aWZmOlhSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpSZXNvbHV0aW9uVW5pdD4yPC90aWZmOlJlc29sdXRpb25Vbml0PgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICAgICA8ZXhpZjpQaXhlbFlEaW1lbnNpb24+ODwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4xMDwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDx4bXA6TWV0YWRhdGFEYXRlPjIwMjItMDgtMTZUMjA6NTc6MjYtMDc6MDA8L3htcDpNZXRhZGF0YURhdGU+CiAgICAgICAgIDx4bXA6Q3JlYXRlRGF0ZT4yMDIyLTA4LTE2VDIwOjUxOjQ1LTA3OjAwPC94bXA6Q3JlYXRlRGF0ZT4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5QaXhlbG1hdG9yIFBybyAyLjQuNTwveG1wOkNyZWF0b3JUb29sPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KxWuTugAAADVJREFUGBljYCAH/AcCmD5kNkwMTGOTwBDDEEAyAibHhCRGHBOmE1k1NjGwPLIEMhtZM0E2AC3SJ9vDG+VZAAAAAElFTkSuQmCC
""")

#FIXME: REMOVE THIS
TOKEN = "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"

# A notable Sunday
JULY_31_2022 = time.time(year=2022, month=7, day=31, location="America/Los_Angeles")

GREEN = "#1a7f37" # real github color
# PURPLE = "#8250df" # real github color
# DARK_GRAY = "#57606a"
# LIGHT_GRAY = "#f6f8fa"
WHITE = "#ffffff"
BLACK = "#000000"

TEST_DATA = [(0,1),(1,1),(2,5),(3,0),(4,1),(5,0),(6,0),(7,3),(8,0),(9,1)]

def main(config):
    print(time.now())
    repo_config = config.str("repository") or DEFAULT_REPO
    repo_parts = repo_config.split("/")
    OWNER = repo_parts[0]
    REPO = repo_parts[1]

    [commit_data, commit_label] = commits(OWNER, REPO)
    [issues_data, issues_label] = repo_issues(OWNER, REPO)
    [prs_data, prs_label] = pull_requests(OWNER, REPO)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "start",
            children = [
                title(REPO),
                info_line('commit', commit_data, commit_label),
                info_line('pr', prs_data, prs_label),
                info_line('issue', issues_data, issues_label),
            ]
        ),
    )

# FIXME: unused?
def day_of_week():
    # TODO: Add customized location for time?
    NOW = time.now()
    return math.floor((NOW - JULY_31_2022).hours / 24) % 7

def commits(owner, repo_name):
    url = participation(owner, repo_name)
    resp = http.get(url, auth=(DEFAULT_USER, TOKEN))
    
    commit_data = json.decode(resp.body())
    commit_list = commit_data['all']

    total = 0
    for commit_value in commit_list:
        total += commit_value
    list_length = len(commit_data['all'])
    data_points = []
    for point in commit_list[list_length - 11:list_length - 1]:
        data_points.append((len(data_points), point))

    return data_points, str(total)

def repo_issues(owner, repo_name):
    issue_text = get_value(repo_page(owner, repo_name), "span#issues-repo-tab-count")

    # TODO: requests to issues API go here

    return [TEST_DATA, issue_text]

def pull_requests(owner, repo_name):
    pr_text = get_value(repo_page(owner, repo_name), "span#pull-requests-repo-tab-count")
    
    # TODO: requests to pulls API go here
    
    return [TEST_DATA, pr_text]

def get_value(url, selector):
    resp = http.get(url)
    html_body = html(resp.body())
    text = html_body.find(selector).text()
    if text == None:
        return PLACEHOLDER_TEXT
    else:
        return text

def repo_page(owner, repo):
    return GITHUB + "/" + owner + "/" + repo

def github_api(owner, repo, path):
    return GITHUB_API + "/repos/" + owner + "/" + repo + path

def participation(owner, repo):
    return github_api(owner, repo, "/stats/participation")

def pulls(owner, repo):
    return github_api(owner, repo, "/pulls")

def issues(owner, repo):
    return github_api(owner, repo, "/issues")

def title(repo_name):
    return render.Box(
        child = render.Marquee(
            child = render.Text(content = repo_name, font = "5x8"),
            scroll_direction = "horizontal",
            offset_start = 64,
            offset_end = 64,
            align = "center",
            height = 8,
            width = 64
        ),
        height = 8,
        width = 64
    )

def info_line(type, data, text):
    return render.Row(
        children = [
            render.Box(
                height = 8,
                width = 32,
                child = render.Row(
                    cross_align = "center",
                    expanded = True,
                    main_align = "space_between",
                    children = label(type, text)
                ),
            ),
            plot(GREEN, data)
        ]
    )

# def issue_icon():
#     return render.Box(
#         height = 8,
#         width = 10,
#         child = render.Circle(
#             color = WHITE,
#             diameter = 6,
#             child = render.Circle(
#                 color = BLACK,
#                 diameter = 4,
#                 child = render.Circle(
#                     color = WHITE,
#                     diameter = 2,
#                 )
#             )
#         )
#     )

def label(type, text):
    if type == 'issue':
        image = render.Image(src = IMAGE_ISSUE, width = 10, height = 8)
    elif type == 'commit':
        image = render.Image(src = IMAGE_COMMIT, width = 10, height = 8)
    elif type == 'pr':
        image = render.Image(src = IMAGE_PULL_REQUEST, width = 10, height = 8)
    return [
        image,
        render.Text(content=str(text))
    ]

def plot(color, data):
    max = 0
    for point in data:
        if point[1] > max:
            max = point[1]
    return render.Plot(
            data = data,
            color = color,
            fill_color = color,
            fill = True,
            height = 8,
            width = 32,
            x_lim = (0, 10),
            y_lim = (0, max)
        )

def oauth_handler(params):
    params = json.decode(params)

    res = http.post(
        url = GITHUB_ACCESS_TK,
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            params,
            client_secret = GITHUB_REPO_STATUS_CLIENT_SECRET,
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    return access_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "repository",
                name = "Github Repository",
                desc = "The owner and repository name in the format of <owner/repository>, like tidbyt/community.",
                icon = "boxArchive",
                default = DEFAULT_REPO,
            ),
            schema.OAuth2(
                id = "auth",
                name = "GitHub Repository Status via Tidbyt",
                desc = "Connect your GitHub account.",
                icon = "github",
                handler = oauth_handler,
                client_id = GITHUB_REPO_STATUS_CLIENT_ID,
                authorization_endpoint = GITHUB_AUTHORIZE,
                scopes = [
                    ""
                    # no scope should generate read-only access to public repos
                    # https://docs.github.com/en/developers/apps/building-oauth-apps/scopes-for-oauth-apps#available-scopes
                ],
            ),
        ],
    )