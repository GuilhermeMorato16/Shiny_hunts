Shiny Hunt Pokemon Fire Red
===

Sempre quis fazer uma run no pokemon Fire Red com um "Dream Team", mas com qual tempo vou procurar shiny?

O primeiro que eu quis achar foi um Charmander shiny! Sim clichê, mas acontece.

Pesquisei um pouco e descobri essa opção. Um script em Lua simulando um soft reset.

Usando o emulador BizHawk e a versão 1.1 da rom do Fire Red consegui a chegar um resultado satisfatório.

---

*O script precisa de ajustes para funcionar para os outros iniciais*

Salvando o jogo na frente da pokebola do pokemon desejado e iniciando o script ele começa com um loop de resetar o jogo e verificar o PID do pokemon ao escolher confirmar o pokemon na sua party. No Lua Console do emulador irá mostrar a log: O número da tentativa, o PID, os IVs e se o pokemon é ou não shiny.

Quando ele encontrar um PID referente ao um shiny ele para o Loop e mostra no Log.

---

## Dúvidas?

*O que é PID?*

PID ou Personality ID é um número gerado quando o pokemon aparece. Ele define as informações do pokemon, nature, gênero e o mais importante aqui, se é shiny ou não.


*O que são os IVs?*

IVs (Valores Individuais) são números ocultos que determinam o potencial máximo de cada estatística do Pokémon, como Ataque, Defesa, Ataque Especial, Defesa Especial, Velocidade e HP. Cada IV vai de 0 a 31, sendo que valores maiores garantem stats finais mais altos quando o Pokémon atinge o nível 100.

---

*Essa primeira versão do script ainda só funciona para os iniciais mas pretendo criar um para utilizar no matinho também!*