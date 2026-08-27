using System.IO.Ports;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace TtalkkakTuner;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        ApplicationConfiguration.Initialize();
        Application.Run(new TunerForm());
    }
}

// 액션·버튼·프로필·기본 배치·헤더 생성은 contract/settings-contract.json 이 진실이고
// contract/generated/Contract.cs 로 생성된다. 여기서 다시 적지 않는다.
// 콤보박스에 라벨을 보여 주려면 ToString 이 필요해서 얇게 감싼다.
internal sealed class KeyAction
{
    public string Label { get; }
    public string Macro { get; }
    public KeyAction(ContractAction a) => (Label, Macro) = (a.Label, a.Macro);
    public override string ToString() => Label;
}

internal sealed class TunerForm : Form
{
    private static readonly string[] Buttons = Contract.EditableButtons;
    // btnev 마스크의 비트 순서 (pins.h BTN_* 열거와 동일 — 계약이 보장한다)
    private static readonly string[] PhysicalButtons = Contract.BitOrder;
    private readonly Dictionary<string, string> mappings = new(Contract.DefaultMappings);
    private readonly Dictionary<string, ComboBox> mappingBoxes = [];
    private readonly Dictionary<string, Button> inputTiles = [];
    private readonly List<KeyAction> actions = Contract.Actions.Select(a => new KeyAction(a)).ToList();
    private readonly Dictionary<string, NumericUpDown> values = [];
    private readonly ComboBox profileBox = new() { DropDownStyle = ComboBoxStyle.DropDownList };
    private readonly ComboBox portBox = new() { DropDownStyle = ComboBoxStyle.DropDownList };
    private readonly Label serialStatus = new() { AutoSize = true, ForeColor = Color.DimGray };
    private SerialPort? serial;
    private string serialText = "";

    public TunerForm()
    {
        Text = "딸깍 감도 조절기";
        ClientSize = new Size(900, 760);
        MinimumSize = new Size(820, 680);
        Font = new Font("Segoe UI", 10F);
        StartPosition = FormStartPosition.CenterScreen;

        var tabs = new TabControl { Dock = DockStyle.Fill };
        tabs.TabPages.Add(BuildSettingsPage());
        tabs.TabPages.Add(BuildInputTestPage());
        tabs.TabPages.Add(BuildModeGuidePage());
        Controls.Add(tabs);
        FormClosed += (_, _) => Disconnect();
    }

    private TabPage BuildSettingsPage()
    {
        var page = new TabPage("감도 · 키 배치");
        var root = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoScroll = true, Padding = new Padding(20) };
        root.Controls.Add(new Label { Text = "딸깍 감도 조절기", Font = new Font(Font.FontFamily, 22, FontStyle.Bold), AutoSize = true });
        root.Controls.Add(new Label { Text = "조이스틱 감도와 PC 프로필별 키 배치를 설정한 뒤 펌웨어 폴더에 저장하세요.", AutoSize = true, ForeColor = Color.DimGray, Margin = new Padding(3, 0, 3, 14) });
        root.Controls.Add(BuildSensitivityBox());
        root.Controls.Add(BuildKeyLayoutBox());
        var save = new Button { Text = "펌웨어 설정 저장…", AutoSize = true, BackColor = Color.FromArgb(20, 105, 190), ForeColor = Color.White, FlatStyle = FlatStyle.Flat, Padding = new Padding(12, 6, 12, 6), Margin = new Padding(3, 12, 3, 3) };
        save.Click += (_, _) => SaveHeaders();
        root.Controls.Add(save);
        page.Controls.Add(root);
        return page;
    }

    private GroupBox BuildSensitivityBox()
    {
        var box = new GroupBox { Text = "감도", Width = 830, Height = 290, Padding = new Padding(14) };
        var grid = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 3, RowCount = 1 };
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 35)); grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 45)); grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 20));
        AddSetting(grid, "gdz", "하부 짐벌 데드존", 0.10m, 0, 0.40m, 0.01m, "중립 흔들림을 줄입니다.");
        AddSetting(grid, "tdz", "엄지 스틱 데드존", 0.14m, 0, 0.40m, 0.01m, "커서가 흐르면 올리세요.");
        AddSetting(grid, "gsat", "하부 짐벌 최대 입력", 0.85m, 0.55m, 1m, 0.01m, "낮을수록 빨리 최대가 됩니다.");
        AddSetting(grid, "tsat", "엄지 스틱 최대 입력", 0.90m, 0.55m, 1m, 0.01m, "엄지 스틱 끝 입력 감도입니다.");
        AddSetting(grid, "fps", "FPS 조준 속도", 22, 4, 45, 1, "엄지 스틱 커서 속도입니다.");
        AddSetting(grid, "moba", "MOBA 커서 속도", 16, 4, 45, 1, "스킬 조준용 속도입니다.");
        AddSetting(grid, "desk", "DESK·MEDIA 커서 속도", 14, 4, 45, 1, "웹 탐색용 속도입니다.");
        AddSetting(grid, "gamma", "미세 조준 곡선", 1.8m, 1, 3, 0.1m, "높을수록 중앙이 정밀합니다.");
        AddSetting(grid, "wasd", "WASD 입력 시작점", 0.38m, 0.15m, 0.75m, 0.01m, "낮을수록 민감합니다.");
        AddSetting(grid, "debounce", "버튼 안정화 시간 (ms)", 12, 2, 25, 1, "PCF8575는 12ms 권장.");
        box.Controls.Add(grid); return box;
    }

    private void AddSetting(TableLayoutPanel grid, string id, string label, decimal value, decimal min, decimal max, decimal step, string hint)
    {
        int row = grid.RowCount++; grid.RowStyles.Add(new RowStyle(SizeType.Absolute, 26));
        grid.Controls.Add(new Label { Text = label + "\n" + hint, AutoSize = true, Dock = DockStyle.Fill, Font = new Font(Font, FontStyle.Regular) }, 0, row);
        var slider = new TrackBar { Minimum = 0, Maximum = (int)((max - min) / step), Value = (int)((value - min) / step), TickStyle = TickStyle.None, Dock = DockStyle.Fill };
        var number = new NumericUpDown { Minimum = min, Maximum = max, Value = value, Increment = step, DecimalPlaces = step < 1 ? (step < 0.1m ? 2 : 1) : 0, Dock = DockStyle.Fill };
        slider.ValueChanged += (_, _) => number.Value = min + slider.Value * step;
        number.ValueChanged += (_, _) => slider.Value = (int)((number.Value - min) / step);
        values[id] = number; grid.Controls.Add(slider, 1, row); grid.Controls.Add(number, 2, row);
    }

    private GroupBox BuildKeyLayoutBox()
    {
        var box = new GroupBox { Text = "키 배치", Width = 830, Height = 430, Padding = new Padding(14) };
        var root = new TableLayoutPanel { Dock = DockStyle.Fill, RowCount = 3 };
        root.RowStyles.Add(new RowStyle(SizeType.Absolute, 36)); root.RowStyles.Add(new RowStyle(SizeType.Absolute, 35)); root.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        profileBox.Items.AddRange(Contract.Profiles.Take(Contract.DefaultProfileCount)
            .Select(p => (object)p.Tag).ToArray()); profileBox.SelectedIndex = 0;
        profileBox.SelectedIndexChanged += (_, _) => LoadProfile();
        root.Controls.Add(profileBox, 0, 0);
        root.Controls.Add(new Label { Text = "MODE 링과 스틱 클릭은 모드 전환·캘리브레이션 기능에 쓰이므로 고정입니다.", AutoSize = true, ForeColor = Color.DimGray, Dock = DockStyle.Fill }, 0, 1);
        var grid = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 4, RowCount = 4 };
        for (int i = 0; i < 4; i++) grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 25));
        foreach (var button in Buttons)
        {
            var cell = new FlowLayoutPanel { FlowDirection = FlowDirection.TopDown, Dock = DockStyle.Fill, Margin = new Padding(5) };
            var combo = new ComboBox { Width = 170, DropDownStyle = ComboBoxStyle.DropDownList };
            combo.Items.AddRange(actions.Cast<object>().ToArray()); combo.SelectedIndexChanged += (_, _) => SaveCurrentProfile();
            mappingBoxes[button] = combo;
            cell.Controls.Add(new Label { Text = button, Font = new Font(Font, FontStyle.Bold), AutoSize = true }); cell.Controls.Add(combo);
            grid.Controls.Add(cell);
        }
        root.Controls.Add(grid, 0, 2); box.Controls.Add(root); LoadProfile(); return box;
    }

    private TabPage BuildInputTestPage()
    {
        var page = new TabPage("실시간 입력 테스트");
        var root = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, Padding = new Padding(20) };
        root.Controls.Add(new Label { Text = "실시간 입력 테스트", Font = new Font(Font.FontFamily, 20, FontStyle.Bold), AutoSize = true });
        root.Controls.Add(new Label { Text = "diagpcf 진단 펌웨어를 올리고 COM 포트를 연결하세요. 실제로 눌린 버튼은 초록색으로 표시됩니다.", AutoSize = true, ForeColor = Color.DimGray, Margin = new Padding(3, 0, 3, 10) });
        var ports = new FlowLayoutPanel { Width = 830, Height = 42 };
        portBox.Width = 260; ports.Controls.Add(portBox);
        var refresh = new Button { Text = "포트 새로 고침", AutoSize = true }; refresh.Click += (_, _) => RefreshPorts(); ports.Controls.Add(refresh);
        var connect = new Button { Text = "연결 / 해제", AutoSize = true }; connect.Click += (_, _) => ToggleConnection(); ports.Controls.Add(connect);
        root.Controls.Add(ports); root.Controls.Add(serialStatus);
        var grid = new TableLayoutPanel { Width = 830, Height = 300, ColumnCount = 4, RowCount = 4, Margin = new Padding(3, 18, 3, 3) };
        for (int i = 0; i < 4; i++) { grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 25)); grid.RowStyles.Add(new RowStyle(SizeType.Percent, 25)); }
        foreach (var button in PhysicalButtons)
        {
            var tile = new Button { Text = button + "\n" + PhysicalHint(button), Dock = DockStyle.Fill, FlatStyle = FlatStyle.Flat, BackColor = Color.FromArgb(238, 240, 243), Font = new Font(Font.FontFamily, 13, FontStyle.Bold), Enabled = false };
            inputTiles[button] = tile; grid.Controls.Add(tile);
        }
        root.Controls.Add(grid); page.Controls.Add(root); RefreshPorts(); return page;
    }

    private TabPage BuildModeGuidePage()
    {
        var page = new TabPage("모드 안내");
        var text = new Label { Dock = DockStyle.Fill, Padding = new Padding(28), Font = new Font("Segoe UI", 12), Text = "PC 모드\n\nMODE 링을 짧게 누르면 FPS → MOBA → DESK → MEDIA를 순환합니다.\n\nMEDIA 기본 동작\n· F1/F2: 뒤로/앞으로  · F3: 주소창 검색\n· F5: YouTube 검색  · F7/U2: 재생·정지\n· U1/U3: 10초 뒤로/앞으로  · M2: 전체화면\n\nNintendo Switch 게임 모드\n\nMODE 링을 2.5초 이상 누르고 떼면 Switch 게임패드 모드로 전환됩니다. 하부 짐벌은 왼쪽 스틱, 엄지 스틱은 오른쪽 스틱으로 동작합니다. 다시 2.5초 누르면 PC 모드로 돌아옵니다.", AutoSize = false };
        page.Controls.Add(text); return page;
    }

    private void LoadProfile()
    {
        if (profileBox.SelectedItem is not string profile) return;
        foreach (var button in Buttons)
        {
            string macro = mappings[$"{profile}_{button}"];
            mappingBoxes[button].SelectedItem = actions.FirstOrDefault(a => a.Macro == macro) ?? actions[0];
        }
    }

    private void SaveCurrentProfile()
    {
        if (profileBox.SelectedItem is not string profile) return;
        foreach (var button in Buttons)
            if (mappingBoxes.TryGetValue(button, out var combo) && combo.SelectedItem is KeyAction action)
                mappings[$"{profile}_{button}"] = action.Macro;
    }

    private void SaveHeaders()
    {
        SaveCurrentProfile();
        using var dialog = new FolderBrowserDialog { Description = "ttalkkak 펌웨어 폴더를 선택하세요." };
        if (dialog.ShowDialog() != DialogResult.OK) return;
        File.WriteAllText(Path.Combine(dialog.SelectedPath, "sensitivity_override.h"), SensitivityHeader(), new UTF8Encoding(false));
        File.WriteAllText(Path.Combine(dialog.SelectedPath, "mapping_override.h"), MappingHeader(), new UTF8Encoding(false));
        MessageBox.Show("감도와 키 배치를 저장했습니다. build.sh로 펌웨어를 다시 업로드하세요.", "저장 완료", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    private double Num(string id) => (double)values[id].Value;

    /// 헤더 생성은 계약(Contract.cs)이 담당한다. macOS 와 byte-for-byte 같아야 한다.
    private string SensitivityHeader() => Contract.SensitivityHeader(new Dictionary<string, double>
    {
        ["gdz"] = Num("gdz"), ["tdz"] = Num("tdz"), ["gsat"] = Num("gsat"), ["tsat"] = Num("tsat"),
        ["gamma"] = Num("gamma"), ["fps"] = Num("fps"), ["moba"] = Num("moba"),
        ["desk"] = Num("desk"), ["wasd"] = Num("wasd"), ["debounce"] = Num("debounce"),
    });

    private string MappingHeader() => Contract.MappingHeader(
        Contract.DefaultProfileCount,
        Contract.Profiles.ToDictionary(p => p.Tag, p => p.DefaultName),
        mappings);

    private void RefreshPorts()
    {
        var selected = portBox.SelectedItem?.ToString(); portBox.Items.Clear();
        portBox.Items.AddRange(SerialPort.GetPortNames().Order().Cast<object>().ToArray());
        if (selected is not null && portBox.Items.Contains(selected)) portBox.SelectedItem = selected;
        else if (portBox.Items.Count > 0) portBox.SelectedIndex = 0;
        serialStatus.Text = portBox.Items.Count == 0 ? "COM 포트를 찾지 못했습니다." : "COM 포트를 선택한 뒤 연결하세요.";
    }

    private void ToggleConnection()
    {
        if (serial is not null) { Disconnect(); return; }
        if (portBox.SelectedItem is not string port) { serialStatus.Text = "COM 포트를 선택하세요."; return; }
        try
        {
            serial = new SerialPort(port, 115200) { NewLine = "\n", DtrEnable = true, RtsEnable = true };
            serial.DataReceived += SerialReceived; serial.Open(); serialStatus.Text = "연결됨 — 버튼을 누르면 초록색으로 표시됩니다.";
        }
        catch (Exception ex) { serialStatus.Text = "연결 실패: " + ex.Message; Disconnect(); }
    }

    private void Disconnect()
    {
        if (serial is not null) { try { serial.DataReceived -= SerialReceived; serial.Close(); serial.Dispose(); } catch { } serial = null; }
        foreach (var tile in inputTiles.Values) tile.BackColor = Color.FromArgb(238, 240, 243);
        serialStatus.Text = "연결 해제됨";
    }

    private void SerialReceived(object? sender, SerialDataReceivedEventArgs e)
    {
        try { serialText += serial?.ReadExisting() ?? ""; }
        catch { return; }
        var lines = serialText.Split('\n'); serialText = lines.Last();
        foreach (var line in lines.SkipLast(1))
        {
            var match = Regex.Match(line, @"btnev=([0-9A-Fa-f]{4})");
            if (!match.Success) continue;
            int mask = Convert.ToInt32(match.Groups[1].Value, 16);
            BeginInvoke(() => UpdateTiles(mask));
        }
    }

    private void UpdateTiles(int mask)
    {
        for (int i = 0; i < PhysicalButtons.Length; i++)
            inputTiles[PhysicalButtons[i]].BackColor = (mask & (1 << i)) != 0 ? Color.FromArgb(45, 170, 95) : Color.FromArgb(238, 240, 243);
    }

    private static string PhysicalHint(string b) =>
        Contract.Buttons.First(x => x.Id == b).Slot;
}
