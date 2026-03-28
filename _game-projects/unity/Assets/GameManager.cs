using System.Collections;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class GameManager : MonoBehaviour
{
	public Button saveButton;
	public TMP_Text text;
	public SaveData saveData;

	void Start()
	{
		string fullPath = Application.persistentDataPath;
		Debug.Log("Your IndexedDB Hash Path: " + fullPath);

		// If you only want the hash itself:
		string hashOnly = fullPath.Replace("/idbfs/", "");
		Debug.Log("The Hash is: " + hashOnly);

		var data = LoadData();
		if (data == null)
		{
			saveData = new SaveData();
			saveData.randomString = "user-" + RandomString();
			saveData.level = 1;
			saveData.elapsedTimeInSeconds = 0f;
		}
		else
		{
			saveData = data;
		}

		text.text = $"Random String: {saveData.randomString}\nLevel: {saveData.level}\nElapsed Time: {saveData.elapsedTimeInSeconds:F2} seconds";

		saveButton.onClick.AddListener(() =>
		{
			string json = JsonUtility.ToJson(saveData);
			PlayerPrefs.SetString("saveData", json);
			PlayerPrefs.Save();
		});

		StartCoroutine(StartTimer());
	}

	private IEnumerator StartTimer()
	{
		var wait = new WaitForSeconds(0.1f);
		while (true)
		{
			saveData.elapsedTimeInSeconds += 0.1f;
			if (saveData.elapsedTimeInSeconds >= 10f)
			{
				saveData.elapsedTimeInSeconds = 0f;
				saveData.level++;
				saveData.randomString = "user-" + RandomString();
			}
			text.text = $"Random String: {saveData.randomString}\nLevel: {saveData.level}\nElapsed Time: {saveData.elapsedTimeInSeconds:F2} seconds";
			yield return wait;
		}
	}

	private SaveData LoadData()
	{
		string json = PlayerPrefs.GetString("saveData", "");
		if (json == "")
		{
			return null;
		}

		return JsonUtility.FromJson<SaveData>(json);
	}

	private string RandomString()
	{
		const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
		char[] stringChars = new char[10];
		for (int i = 0; i < stringChars.Length; i++)
		{
			stringChars[i] = chars[Random.Range(0, chars.Length)];
		}
		return new string(stringChars);
	}

}

public class SaveData
{
	public string randomString;
	public int level;
	public float elapsedTimeInSeconds;
}