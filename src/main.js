import './style.css';

const games = {
	unity: { src: './unity-game/index.html', label: 'Unity Game' },
	defold: { src: './defold-game/index.html', label: 'Defold Game' },
};

let current = 'unity';

document.querySelector('#app').innerHTML = `
  <div id="switcher">
    <button id="btn-unity" class="game-btn active">Unity Game</button>
    <button id="btn-defold" class="game-btn">Defold Game</button>
  </div>
  <iframe id="game-frame" src="${games.unity.src}" title="${games.unity.label}" style="width:100%;height:calc(100vh - 48px);border:0;display:block;"></iframe>
`;

function switchGame(key) {
	if (key === current) return;
	current = key;
	const frame = document.getElementById('game-frame');
	frame.src = games[key].src;
	frame.title = games[key].label;
	document.querySelectorAll('.game-btn').forEach(btn => btn.classList.remove('active'));
	document.getElementById(`btn-${key}`).classList.add('active');
}

document.getElementById('btn-unity').addEventListener('click', () => switchGame('unity'));
document.getElementById('btn-defold').addEventListener('click', () => switchGame('defold'));
